#!/usr/bin/env bash
# fetch-pr-comments.sh
# Fetches and flattens Azure DevOps PR thread comments (GET only).
# Retries transiently failed requests up to five times before emitting an error.
# Null threadContext (general discussion threads) is handled safely throughout.
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
"$script_dir/ensure-env.sh" --require-pat

pull_request_url=""
organization=""
project=""
repository_id=""
pull_request_id=""
include_raw_threads="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pull-request-url) pull_request_url="$2"; shift 2 ;;
    --organization) organization="$2"; shift 2 ;;
    --project) project="$2"; shift 2 ;;
    --repository-id) repository_id="$2"; shift 2 ;;
    --pull-request-id) pull_request_id="$2"; shift 2 ;;
    --include-raw-threads) include_raw_threads="true"; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ -n "$pull_request_url" ]]; then
  parsed="$("$script_dir/parse-pr-url.sh" "$pull_request_url")"
  [[ -z "$organization" ]] && organization="$(jq -r '.organization' <<<"$parsed")"
  [[ -z "$project" ]] && project="$(jq -r '.project' <<<"$parsed")"
  [[ -z "$repository_id" ]] && repository_id="$(jq -r '.repository_id' <<<"$parsed")"
  [[ -z "$pull_request_id" ]] && pull_request_id="$(jq -r '.pull_request_id' <<<"$parsed")"
fi

if [[ -z "$organization" || -z "$project" || -z "$repository_id" || -z "$pull_request_id" ]]; then
  echo "BLOCKER:" >&2
  echo "code: MISSING_INPUT" >&2
  echo "required_input:" >&2
  [[ -z "$organization" ]] && echo "- organization" >&2
  [[ -z "$project" ]] && echo "- project" >&2
  [[ -z "$repository_id" ]] && echo "- repository_id" >&2
  [[ -z "$pull_request_id" ]] && echo "- pull_request_id" >&2
  echo "next_question: Provide a valid Azure DevOps pull request URL or explicit identifiers." >&2
  exit 1
fi

url="https://dev.azure.com/$organization/$project/_apis/git/repositories/$repository_id/pullRequests/$pull_request_id/threads?api-version=7.1"
pr_url="https://dev.azure.com/$organization/$project/_apis/git/repositories/$repository_id/pullRequests/$pull_request_id?api-version=7.1"
work_items_url="https://dev.azure.com/$organization/$project/_apis/git/repositories/$repository_id/pullRequests/$pull_request_id/workitems?api-version=7.1"

response="$(
  curl -fsS \
    --retry 5 \
    --retry-delay 2 \
    --retry-max-time 60 \
    --retry-connrefused \
    --retry-all-errors \
    -u ":${AZURE_DEVOPS_PAT}" \
    -H "Accept: application/json" \
    "$url"
)" || {
  echo "ERROR:" >&2
  echo "code: FETCH_FAILED" >&2
  echo "stage: fetch" >&2
  echo "message: Failed to fetch PR threads for pull request $pull_request_id in $organization/$project/$repository_id after bounded retries." >&2
  echo "recovery: Check AZURE_DEVOPS_PAT, identifiers, and network connectivity." >&2
  exit 1
}

pr_response="$(
  curl -fsS \
    --retry 5 \
    --retry-delay 2 \
    --retry-max-time 60 \
    --retry-connrefused \
    --retry-all-errors \
    -u ":${AZURE_DEVOPS_PAT}" \
    -H "Accept: application/json" \
    "$pr_url"
)" || {
  echo "ERROR:" >&2
  echo "code: FETCH_FAILED" >&2
  echo "stage: fetch" >&2
  echo "message: Failed to fetch pull request details for $pull_request_id in $organization/$project/$repository_id after bounded retries." >&2
  echo "recovery: Check AZURE_DEVOPS_PAT, identifiers, and network connectivity." >&2
  exit 1
}

linked_work_items_response="$(
  curl -fsS \
    --retry 5 \
    --retry-delay 2 \
    --retry-max-time 60 \
    --retry-connrefused \
    --retry-all-errors \
    -u ":${AZURE_DEVOPS_PAT}" \
    -H "Accept: application/json" \
    "$work_items_url"
)" || {
  echo "ERROR:" >&2
  echo "code: FETCH_FAILED" >&2
  echo "stage: fetch" >&2
  echo "message: Failed to fetch linked pull request work items for $pull_request_id in $organization/$project/$repository_id after bounded retries." >&2
  echo "recovery: Check AZURE_DEVOPS_PAT, identifiers, and network connectivity." >&2
  exit 1
}

linked_work_item_ids="$(jq -c '[.value[]?.id | tonumber?] | map(select(. != null))' <<<"$linked_work_items_response")"
linked_work_item_details='{"value":[]}'
work_item_count="$(jq -r 'length' <<<"$linked_work_item_ids")"
if (( work_item_count > 0 )); then
  # Keep IDs per request bounded to avoid URL-length limits through proxies/APIs.
  batch_size=100
  linked_work_item_values='[]'
  for ((offset=0; offset<work_item_count; offset+=batch_size)); do
    work_item_ids_csv="$(jq -r --argjson offset "$offset" --argjson batch_size "$batch_size" '.[$offset:($offset + $batch_size)] | join(",")' <<<"$linked_work_item_ids")"
    [[ -z "$work_item_ids_csv" ]] && continue
    linked_work_items_details_url="https://dev.azure.com/$organization/$project/_apis/wit/workitems?ids=$work_item_ids_csv&fields=System.Title,System.WorkItemType,System.State&api-version=7.1"
    linked_work_item_batch="$(
      curl -fsS \
        --retry 5 \
        --retry-delay 2 \
        --retry-max-time 60 \
        --retry-connrefused \
        --retry-all-errors \
        -u ":${AZURE_DEVOPS_PAT}" \
        -H "Accept: application/json" \
        "$linked_work_items_details_url"
    )" || {
      echo "ERROR:" >&2
      echo "code: FETCH_FAILED" >&2
      echo "stage: fetch" >&2
      echo "message: Failed to fetch linked work item details for pull request $pull_request_id in $organization/$project/$repository_id after bounded retries." >&2
      echo "recovery: Check AZURE_DEVOPS_PAT, identifiers, and network connectivity." >&2
      exit 1
    }
    linked_work_item_values="$(jq -cn --argjson existing "$linked_work_item_values" --argjson batch "$linked_work_item_batch" '$existing + ($batch.value // [])')"
  done
  linked_work_item_details="$(jq -cn --argjson values "$linked_work_item_values" '{value: $values}')"
fi

# ── Flatten threads into individual comment records ───────────────────────────
# Guard: threads without a threadContext (general discussion threads) are handled
# safely throughout.  jq null-propagates through missing keys, so all
# .threadContext.* accesses below return null rather than erroring when
# threadContext is absent.  comment_side falls through to "general" in that
# case, which is the correct value and satisfies the schema enum.
jq \
  --arg organization "$organization" \
  --arg project "$project" \
  --arg repository_id "$repository_id" \
  --argjson pull_request_id "$pull_request_id" \
  --argjson pull_request "$pr_response" \
  --argjson linked_work_items "$linked_work_item_details" \
  --arg include_raw_threads "$include_raw_threads" \
  '
  def redact_text:
    if . == null then null
    else
      gsub("(?i)Bearer\\s+[A-Za-z0-9._-]+"; "Bearer [REDACTED]")
      | gsub("\\b(?:ghp_[A-Za-z0-9]+|AZURE_DEVOPS_PAT|[A-Za-z0-9]{20,}\\.[A-Za-z0-9._-]{10,})\\b"; "[REDACTED]")
    end;

  def normalize_repo_root_path:
    if . == null then null
    elif . == "" then null
    else
      (ltrimstr("/") | split("/") | map(select(length > 0))) as $segments
      # Only reject explicit traversal segments "." or "..".
      # Filenames with dots like "config.prod.json" remain valid.
      | if ($segments | map(. == "." or . == "..") | any) then null
        elif ($segments | length) == 0 then null
        else "/" + ($segments | join("/"))
        end
    end;

  # Returns the start-anchor object for the given side.
  # Null-safe: if threadContext or the nested key is absent, returns null.
  def file_object(side):
    if side == "right" then .threadContext.rightFileStart
    elif side == "left" then .threadContext.leftFileStart
    else null end;

  def file_end_object(side):
    if side == "right" then .threadContext.rightFileEnd
    elif side == "left" then .threadContext.leftFileEnd
    else null end;

  # Derives the comment side from which anchor objects are non-null.
  # Falls through to "general" when threadContext is null or both sides are absent
  # (e.g. PR-level discussion threads), which is the correct schema value.
  def comment_side:
    if (.threadContext.rightFileStart != null or .threadContext.rightFileEnd != null) then "right"
    elif (.threadContext.leftFileStart != null or .threadContext.leftFileEnd != null) then "left"
    else "general"
    end;

  . as $root
  | ($root.value // []) as $threads
  | {
      organization: $organization,
      project: $project,
      repository_id: $repository_id,
      pull_request_id: $pull_request_id,
      pull_request: {
        id: ($pull_request.pullRequestId // null),
        title: ($pull_request.title // ""),
        source_branch: ($pull_request.sourceRefName // ""),
        target_branch: ($pull_request.targetRefName // ""),
        status: ($pull_request.status // null),
        creation_date: ($pull_request.creationDate // null),
        closed_date: ($pull_request.closedDate // null)
      },
      linked_work_items: [
        ($linked_work_items.value // [])[]
        | {
            id: (.id | tonumber? // null),
            title: (.fields["System.Title"] // ""),
            type: (.fields["System.WorkItemType"] // ""),
            state: (.fields["System.State"] // ""),
            url: (.url // null)
          }
      ],
      thread_count: ($threads | length),
      comment_count: ($threads | map(.comments // []) | flatten | length),
      comments: [
        $threads[]
        | . as $thread
        | ($thread | comment_side) as $side
        | ($thread.comments // [])[]
        | {
            thread_id: $thread.id,
            comment_id: .id,
            parent_comment_id: .parentCommentId,
            author: .author.displayName,
            content: (.content | redact_text),
            file_path: (($thread.threadContext.filePath // null) | normalize_repo_root_path),
            side: $side,
            start_line: ($thread | file_object($side) | .line?),
            end_line: ($thread | file_end_object($side) | .line?),
            start_offset: ($thread | file_object($side) | .offset?),
            end_offset: ($thread | file_end_object($side) | .offset?),
            thread_status: $thread.status,
            thread_is_deleted: ($thread.isDeleted // false),
            comment_is_deleted: (.isDeleted // false),
            published_date: .publishedDate,
            last_updated_date: .lastUpdatedDate
          }
      ],
      raw_threads: (if $include_raw_threads == "true" then $threads else null end)
    }
  ' <<<"$response"
