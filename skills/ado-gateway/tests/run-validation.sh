#!/usr/bin/env bash
# run-validation.sh
# Executable validation harness for ado-gateway.
set -euo pipefail

skill_dir="$(cd "$(dirname "$0")/.." && pwd)"
scripts_dir="$skill_dir/scripts"
examples_dir="$skill_dir/assets/examples"
schema="$skill_dir/assets/schemas/ado-openspec-handoff.schema.json"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

for script in \
  ensure-env.sh \
  parse-pr-url.sh \
  normalize-work-item.sh \
  emit-handoff.sh \
  validate-handoff.sh \
  write-guard.sh \
  create-work-item.sh \
  create-work-item-comment.sh \
  create-pull-request.sh \
  create-pr-comment.sh \
  format-work-item-mention.sh \
  resolve-ado-user.sh; do
  [[ -f "$scripts_dir/$script" ]] || fail "missing $script"
done
pass "required local scripts exist"

command -v jq >/dev/null 2>&1 || fail "jq is required for validation"
command -v python3 >/dev/null 2>&1 || fail "python3 is required for validation"
if command -v timeout >/dev/null 2>&1; then
  validate_handoff_with_limit() {
    timeout 10 "$scripts_dir/validate-handoff.sh"
  }
else
  validate_handoff_with_limit() {
    "$scripts_dir/validate-handoff.sh"
  }
fi
pass "required local validation dependencies exist"

for example in "$examples_dir"/*.json; do
  validate_handoff_with_limit < "$example" > /dev/null
  pass "schema-valid example $(basename "$example")"
done

parsed="$($scripts_dir/parse-pr-url.sh 'https://dev.azure.com/example-org/example-project/_git/example-repo/pullrequest/123')"
[[ "$(jq -r '.organization' <<<"$parsed")" == "example-org" ]] || fail "PR URL organization parse failed"
[[ "$(jq -r '.project' <<<"$parsed")" == "example-project" ]] || fail "PR URL project parse failed"
[[ "$(jq -r '.repository_id' <<<"$parsed")" == "example-repo" ]] || fail "PR URL repository parse failed"
[[ "$(jq -r '.pull_request_id' <<<"$parsed")" == "123" ]] || fail "PR URL id parse failed"
pass "PR URL parsing is deterministic"

if "$scripts_dir/parse-pr-url.sh" 'https://github.com/org/repo/pull/1' >"$tmp_dir/invalid.out" 2>"$tmp_dir/invalid.err"; then
  fail "invalid PR URL unexpectedly succeeded"
fi
grep -q 'code: INVALID_PR_URL' "$tmp_dir/invalid.err" || fail "invalid PR URL did not produce INVALID_PR_URL blocker"
pass "invalid PR URLs produce blocker output"

cat > "$tmp_dir/work-item-raw.json" <<'JSON'
{
  "id": 1234,
  "fields": {
    "System.WorkItemType": "User Story",
    "System.Title": "Checkout supports discount codes",
    "System.Description": "<p>Add <b>discount</b> code support.</p>",
    "Microsoft.VSTS.Common.AcceptanceCriteria": "<ul><li>Apply valid code</li></ul>",
    "System.Tags": "checkout;discount",
    "System.State": "New"
  }
}
JSON

"$scripts_dir/normalize-work-item.sh" < "$tmp_dir/work-item-raw.json" > "$tmp_dir/work-item-normalized.json"
[[ "$(jq -r '.id | type' "$tmp_dir/work-item-normalized.json")" == "number" ]] || fail "work_item.id must be numeric"
[[ "$(jq -r '.description' "$tmp_dir/work-item-normalized.json")" == "Add discount code support." ]] || fail "HTML description normalization failed"
pass "work item normalization keeps numeric id and strips HTML"

jq '.work_item.id = "1234"' "$examples_dir/work-item-only.json" > "$tmp_dir/bad-string-id.json"
if validate_handoff_with_limit < "$tmp_dir/bad-string-id.json" > /dev/null 2>"$tmp_dir/string-id.err"; then
  fail "schema accepted string work_item.id"
fi
grep -q 'stage: emit' "$tmp_dir/string-id.err" || fail "string id schema error did not identify emit stage"
pass "schema rejects stringified work_item.id"

"$scripts_dir/emit-handoff.sh" \
  --mode work-item \
  --organization example-org \
  --project example-project \
  --work-item-id 1234 \
  --work-item-file "$tmp_dir/work-item-normalized.json" \
  > "$tmp_dir/handoff.json"
validate_handoff_with_limit < "$tmp_dir/handoff.json" > /dev/null
[[ "$(jq -r '.source.work_item_id | type' "$tmp_dir/handoff.json")" == "number" ]] || fail "source.work_item_id must be numeric"
[[ "$(jq -r '.work_item.id | type' "$tmp_dir/handoff.json")" == "number" ]] || fail "emitted work_item.id must be numeric"
pass "emit path validates schema and preserves numeric ids"

# Read-mode scripts must remain mutation-free. Write-mode scripts are allowed to POST
# only behind the explicit write guard.
for read_script in fetch-work-item.sh fetch-pr-comments.sh generate-handoff.sh emit-handoff.sh normalize-work-item.sh parse-pr-url.sh validate-handoff.sh ensure-env.sh; do
  if grep -InE '\bcurl\b.*(-X|--request)[[:space:]]*(POST|PATCH|PUT|DELETE)' "$scripts_dir/$read_script"; then
    fail "mutating curl request detected in read script $read_script"
  fi
done
pass "read scripts contain no mutating curl request"

for write_script in create-work-item.sh create-work-item-comment.sh create-pull-request.sh create-pr-comment.sh; do
  grep -q -- '--confirm)' "$scripts_dir/$write_script" || fail "$write_script is missing --confirm parsing"
  grep -q 'requires_confirmation:true' "$scripts_dir/$write_script" || fail "$write_script is missing requires_confirmation dry-run contract"
  grep -q 'dry_run:true' "$scripts_dir/$write_script" || fail "$write_script is missing dry-run output"
done
pass "write scripts require explicit confirmation and expose dry-run output"

mention_markup="$($scripts_dir/format-work-item-mention.sh --mention-id 'aad.1234' --display-name 'Ada Lovelace')"
[[ "$mention_markup" == '<a href="#" data-vss-mention="version:2.0,{aad.1234}">@Ada Lovelace</a>' ]] || fail "mention helper markup output mismatch"
pass "mention helper emits deterministic markup"

grep -q '/_apis/identities' "$scripts_dir/resolve-ado-user.sh" || fail "resolve-ado-user must use identities endpoint"
grep -q 'properties=Mail,Account,SignInAddress' "$scripts_dir/resolve-ado-user.sh" || fail "resolve-ado-user must request identity email properties"
grep -q -- '--mention-id "$mention_id"' "$scripts_dir/resolve-ado-user.sh" || fail "resolve-ado-user must build markup from mention_id"
grep -q 'mention_id' "$scripts_dir/resolve-ado-user.sh" || fail "resolve-ado-user output must include mention_id"
pass "resolve-ado-user uses identity lookup and mention id output"

wi_plan="$($scripts_dir/create-work-item.sh --organization example-org --project example-project --type Bug --title 'Bug title' --description 'Bug description')"
[[ "$(jq -r '.dry_run' <<<"$wi_plan")" == "true" ]] || fail "work-item dry-run did not mark dry_run=true"
[[ "$(jq -r '.method' <<<"$wi_plan")" == "POST" ]] || fail "work-item dry-run method must be POST"
[[ "$(jq -r '.body[0].path' <<<"$wi_plan")" == "/fields/System.Title" ]] || fail "work-item dry-run missing title patch"
pass "create-work-item dry-run produces deterministic action plan"

pr_plan="$($scripts_dir/create-pull-request.sh --organization example-org --project example-project --repository-id example-repo --source-branch feature/demo --target-branch main --title 'PR title' --description 'PR description')"
[[ "$(jq -r '.dry_run' <<<"$pr_plan")" == "true" ]] || fail "pull-request dry-run did not mark dry_run=true"
[[ "$(jq -r '.body.sourceRefName' <<<"$pr_plan")" == "refs/heads/feature/demo" ]] || fail "pull-request dry-run did not normalize source branch"
pass "create-pull-request dry-run produces deterministic action plan"

wi_comment_plan="$($scripts_dir/create-work-item-comment.sh --organization example-org --project example-project --work-item-id 456 --text '<p>Looks good</p>')"
[[ "$(jq -r '.dry_run' <<<"$wi_comment_plan")" == "true" ]] || fail "work-item comment dry-run did not mark dry_run=true"
[[ "$(jq -r '.method' <<<"$wi_comment_plan")" == "POST" ]] || fail "work-item comment dry-run method must be POST"
[[ "$(jq -r '.body.text' <<<"$wi_comment_plan")" == "<p>Looks good</p>" ]] || fail "work-item comment dry-run body text mismatch"
pass "create-work-item-comment dry-run produces deterministic action plan"

comment_plan="$($scripts_dir/create-pr-comment.sh --mode thread --organization example-org --project example-project --repository-id example-repo --pull-request-id 123 --content 'Review comment' --file-path /src/order.ts --line 42)"
[[ "$(jq -r '.dry_run' <<<"$comment_plan")" == "true" ]] || fail "PR comment dry-run did not mark dry_run=true"
[[ "$(jq -r '.body.threadContext.filePath' <<<"$comment_plan")" == "/src/order.ts" ]] || fail "PR comment dry-run missing inline file path"
[[ "$(jq -r '.body.threadContext.rightFileStart.line' <<<"$comment_plan")" == "42" ]] || fail "PR comment dry-run wrong start line"
[[ "$(jq -r '.body.threadContext.rightFileEnd.line' <<<"$comment_plan")" == "42" ]] || fail "PR comment dry-run end line should default to start line"
pass "create-pr-comment dry-run produces deterministic inline action plan"

comment_range_plan="$($scripts_dir/create-pr-comment.sh --mode thread --organization example-org --project example-project --repository-id example-repo --pull-request-id 123 --content 'Range comment' --file-path src/order.ts --line 10 --end-line 20)"
[[ "$(jq -r '.dry_run' <<<"$comment_range_plan")" == "true" ]] || fail "PR comment range dry-run did not mark dry_run=true"
[[ "$(jq -r '.body.threadContext.filePath' <<<"$comment_range_plan")" == "/src/order.ts" ]] || fail "PR comment range dry-run did not normalize file path to repo-root format"
[[ "$(jq -r '.body.threadContext.rightFileStart.line' <<<"$comment_range_plan")" == "10" ]] || fail "PR comment range dry-run wrong start line"
[[ "$(jq -r '.body.threadContext.rightFileEnd.line' <<<"$comment_range_plan")" == "20" ]] || fail "PR comment range dry-run wrong end line"
pass "create-pr-comment dry-run produces deterministic multi-line range action plan"

cat > "$tmp_dir/pr-comments-normalized.json" <<'JSON'
{
  "comments": [
    {
      "thread_id": 1,
      "comment_id": 1,
      "parent_comment_id": 0,
      "author": "Reviewer",
      "content": "Looks good",
      "file_path": "/src/order.ts",
      "side": "right",
      "start_line": 10,
      "end_line": 10,
      "start_offset": 1,
      "end_offset": 1,
      "thread_status": "active",
      "thread_is_deleted": false,
      "comment_is_deleted": false,
      "published_date": "2026-04-29T08:00:00Z",
      "last_updated_date": "2026-04-29T08:00:00Z"
    }
  ],
  "pull_request": {
    "id": 123,
    "title": "Demo PR",
    "source_branch": "refs/heads/feature/demo",
    "target_branch": "refs/heads/main",
    "status": "active",
    "creation_date": "2026-04-29T08:00:00Z",
    "closed_date": null
  },
  "linked_work_items": [
    {
      "id": 456,
      "title": "Demo work item",
      "type": "User Story",
      "state": "Active",
      "url": "https://dev.azure.com/example-org/example-project/_apis/wit/workItems/456"
    }
  ]
}
JSON

"$scripts_dir/emit-handoff.sh" \
  --mode pr-comments \
  --organization example-org \
  --project example-project \
  --repository-id example-repo \
  --pull-request-id 123 \
  --pr-comments-file "$tmp_dir/pr-comments-normalized.json" \
  > "$tmp_dir/handoff-pr-comments.json"
validate_handoff_with_limit < "$tmp_dir/handoff-pr-comments.json" > /dev/null
[[ "$(jq -r '.pull_request.source_branch' "$tmp_dir/handoff-pr-comments.json")" == "refs/heads/feature/demo" ]] || fail "handoff missing pull_request.source_branch"
[[ "$(jq -r '.pull_request.target_branch' "$tmp_dir/handoff-pr-comments.json")" == "refs/heads/main" ]] || fail "handoff missing pull_request.target_branch"
[[ "$(jq -r '.linked_work_items[0].id' "$tmp_dir/handoff-pr-comments.json")" == "456" ]] || fail "handoff missing linked work item details"
pass "emit path includes PR branch metadata and linked work item details"

if "$scripts_dir/create-pr-comment.sh" --mode thread --organization example-org --project example-project --repository-id example-repo --pull-request-id 123 --content 'x' --file-path src/order.ts --line 20 --end-line 10 >"$tmp_dir/range.out" 2>"$tmp_dir/range.err"; then
  fail "end-line < line unexpectedly succeeded"
fi
grep -q 'end-line must be greater than or equal to' "$tmp_dir/range.err" || fail "inverted range did not produce expected error"
pass "create-pr-comment rejects end-line less than line"

if "$scripts_dir/create-pr-comment.sh" --mode thread --organization example-org --project example-project --repository-id example-repo --pull-request-id 123 --content 'x' --end-line 5 >"$tmp_dir/endline-no-file.out" 2>"$tmp_dir/endline-no-file.err"; then
  fail "--end-line without --file-path unexpectedly succeeded"
fi
grep -q 'end-line requires --file-path' "$tmp_dir/endline-no-file.err" || fail "--end-line without --file-path did not produce expected error"
pass "create-pr-comment rejects --end-line without --file-path"

if "$scripts_dir/create-pr-comment.sh" --mode thread --organization example-org --project example-project --repository-id example-repo --pull-request-id 123 --content 'x' --file-path '/' --line 1 >"$tmp_dir/root-path.out" 2>"$tmp_dir/root-path.err"; then
  fail "root-only --file-path unexpectedly succeeded"
fi
grep -q 'must include a file path under the repository root' "$tmp_dir/root-path.err" || fail "root-only --file-path did not produce expected error"
pass "create-pr-comment rejects root-only file paths"

if "$scripts_dir/create-pr-comment.sh" --mode thread --organization example-org --project example-project --repository-id example-repo --pull-request-id 123 --content 'x' --file-path '/src/../secrets.txt' --line 1 >"$tmp_dir/traversal-path.out" 2>"$tmp_dir/traversal-path.err"; then
  fail "path traversal --file-path unexpectedly succeeded"
fi
grep -q 'must stay within the repository root' "$tmp_dir/traversal-path.err" || fail "path traversal --file-path did not produce expected error"
pass "create-pr-comment rejects file paths with traversal segments"

if "$scripts_dir/create-pr-comment.sh" --mode thread --organization example-org --project example-project --repository-id example-repo --pull-request-id 123 --content 'x' --file-path '/src/..' --line 1 >"$tmp_dir/trailing-traversal-path.out" 2>"$tmp_dir/trailing-traversal-path.err"; then
  fail "trailing path traversal --file-path unexpectedly succeeded"
fi
grep -q 'must stay within the repository root' "$tmp_dir/trailing-traversal-path.err" || fail "trailing path traversal --file-path did not produce expected error"
pass "create-pr-comment rejects trailing traversal segments"

if "$scripts_dir/create-pr-comment.sh" --mode thread --organization example-org --project example-project --repository-id example-repo --pull-request-id 123 --content 'x' --file-path '\\server\share\file.ts' --line 1 >"$tmp_dir/unc-path.out" 2>"$tmp_dir/unc-path.err"; then
  fail "UNC absolute --file-path unexpectedly succeeded"
fi
grep -q 'must be repo-root-relative and start with' "$tmp_dir/unc-path.err" || fail "UNC absolute --file-path did not produce expected error"
pass "create-pr-comment rejects UNC absolute file paths"

if "$scripts_dir/create-pr-comment.sh" --mode thread --organization example-org --project example-project --repository-id example-repo --pull-request-id 123 --content 'x' --file-path 'C:\repo\file.ts' --line 1 >"$tmp_dir/windows-drive-path.out" 2>"$tmp_dir/windows-drive-path.err"; then
  fail "Windows drive --file-path unexpectedly succeeded"
fi
grep -q 'must be repo-root-relative and start with' "$tmp_dir/windows-drive-path.err" || fail "Windows drive --file-path did not produce expected error"
pass "create-pr-comment rejects Windows drive absolute file paths"

if "$scripts_dir/create-work-item.sh" --organization example-org --project example-project --type Bug --title 'Bug title' --confirm >"$tmp_dir/write.out" 2>"$tmp_dir/write.err"; then
  fail "write execution without PAT unexpectedly succeeded"
fi
grep -q 'code: MISSING_AUTH' "$tmp_dir/write.err" || fail "write execution without PAT did not produce MISSING_AUTH"
pass "write execution requires --confirm and AZURE_DEVOPS_PAT"

printf '\nADO Gateway validation completed successfully.\n'
