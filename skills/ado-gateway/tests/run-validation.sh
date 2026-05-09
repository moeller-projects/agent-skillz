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
  create-pull-request.sh \
  create-pr-comment.sh; do
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

for write_script in create-work-item.sh create-pull-request.sh create-pr-comment.sh; do
  grep -q 'require_write_confirmation' "$scripts_dir/$write_script" || fail "$write_script is missing write confirmation guard"
  grep -q 'dry_run:true' "$scripts_dir/$write_script" || fail "$write_script is missing dry-run output"
done
pass "write scripts require explicit confirmation and expose dry-run output"

wi_plan="$($scripts_dir/create-work-item.sh --organization example-org --project example-project --type Bug --title 'Bug title' --description 'Bug description')"
[[ "$(jq -r '.dry_run' <<<"$wi_plan")" == "true" ]] || fail "work-item dry-run did not mark dry_run=true"
[[ "$(jq -r '.method' <<<"$wi_plan")" == "POST" ]] || fail "work-item dry-run method must be POST"
[[ "$(jq -r '.body[0].path' <<<"$wi_plan")" == "/fields/System.Title" ]] || fail "work-item dry-run missing title patch"
pass "create-work-item dry-run produces deterministic action plan"

pr_plan="$($scripts_dir/create-pull-request.sh --organization example-org --project example-project --repository-id example-repo --source-branch feature/demo --target-branch main --title 'PR title' --description 'PR description')"
[[ "$(jq -r '.dry_run' <<<"$pr_plan")" == "true" ]] || fail "pull-request dry-run did not mark dry_run=true"
[[ "$(jq -r '.body.sourceRefName' <<<"$pr_plan")" == "refs/heads/feature/demo" ]] || fail "pull-request dry-run did not normalize source branch"
pass "create-pull-request dry-run produces deterministic action plan"

comment_plan="$($scripts_dir/create-pr-comment.sh --mode thread --organization example-org --project example-project --repository-id example-repo --pull-request-id 123 --content 'Review comment' --file-path /src/order.ts --line 42)"
[[ "$(jq -r '.dry_run' <<<"$comment_plan")" == "true" ]] || fail "PR comment dry-run did not mark dry_run=true"
[[ "$(jq -r '.body.threadContext.filePath' <<<"$comment_plan")" == "/src/order.ts" ]] || fail "PR comment dry-run missing inline file path"
pass "create-pr-comment dry-run produces deterministic inline action plan"

if $scripts_dir/create-work-item.sh --organization example-org --project example-project --type Bug --title 'Bug title' --execute >"$tmp_dir/write.out" 2>"$tmp_dir/write.err"; then
  fail "write execution without confirmation unexpectedly succeeded"
fi
grep -q 'code: WRITE_CONFIRMATION_REQUIRED' "$tmp_dir/write.err" || fail "missing write confirmation did not produce WRITE_CONFIRMATION_REQUIRED"
pass "write execution is blocked without explicit confirmation token"

printf '\nADO Gateway validation completed successfully.\n'
