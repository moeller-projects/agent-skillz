#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
"$script_dir/ensure-env.sh"

pull_request_url=""
organization="${ADO_ORGANIZATION:-}"
project="${ADO_PROJECT:-}"
repository_id="${ADO_REPOSITORY_ID:-}"
pull_request_id="${ADO_PULL_REQUEST_ID:-}"
work_item_id="${ADO_WORK_ITEM_ID:-}"
mode=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pull-request-url) pull_request_url="$2"; shift 2 ;;
    --organization) organization="$2"; shift 2 ;;
    --project) project="$2"; shift 2 ;;
    --repository-id) repository_id="$2"; shift 2 ;;
    --pull-request-id) pull_request_id="$2"; shift 2 ;;
    --work-item-id) work_item_id="$2"; shift 2 ;;
    --mode) mode="$2"; shift 2 ;;
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

if [[ -z "$mode" ]]; then
  if [[ -n "$work_item_id" && -n "$pull_request_id" ]]; then
    mode="work-item-plus-pr-comments"
  elif [[ -n "$work_item_id" ]]; then
    mode="work-item"
  elif [[ -n "$pull_request_id" ]]; then
    mode="pr-comments"
  else
    echo "BLOCKER:" >&2
    echo "code: MISSING_INPUT" >&2
    echo "required_input:" >&2
    echo "- work_item_id and/or pull_request_id" >&2
    echo "next_question: Provide a work item id, a pull request id, or a pull request URL." >&2
    exit 1
  fi
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

work_item_file=""
pr_comments_file=""

if [[ "$mode" == "work-item" || "$mode" == "work-item-plus-pr-comments" ]]; then
  if [[ -z "$organization" || -z "$project" || -z "$work_item_id" ]]; then
    echo "BLOCKER:" >&2
    echo "code: MISSING_INPUT" >&2
    echo "required_input:" >&2
    [[ -z "$organization" ]] && echo "- organization" >&2
    [[ -z "$project" ]] && echo "- project" >&2
    [[ -z "$work_item_id" ]] && echo "- work_item_id" >&2
    echo "next_question: Provide organization, project, and work item id before fetching the work item." >&2
    exit 1
  fi
  "$script_dir/fetch-work-item.sh" "$organization" "$project" "$work_item_id" > "$tmp_dir/work-item-raw.json"
  "$script_dir/normalize-work-item.sh" < "$tmp_dir/work-item-raw.json" > "$tmp_dir/work-item-normalized.json"
  work_item_file="$tmp_dir/work-item-normalized.json"
fi

if [[ "$mode" == "pr-comments" || "$mode" == "work-item-plus-pr-comments" ]]; then
  "$script_dir/fetch-pr-comments.sh" \
    --organization "$organization" \
    --project "$project" \
    --repository-id "$repository_id" \
    --pull-request-id "$pull_request_id" \
    > "$tmp_dir/pr-comments.json"
  pr_comments_file="$tmp_dir/pr-comments.json"
fi

emit_args=(--mode "$mode" --organization "$organization" --project "$project" --repository-id "$repository_id")
[[ -n "$work_item_id" ]] && emit_args+=(--work-item-id "$work_item_id")
[[ -n "$pull_request_id" ]] && emit_args+=(--pull-request-id "$pull_request_id")
[[ -n "$work_item_file" ]] && emit_args+=(--work-item-file "$work_item_file")
[[ -n "$pr_comments_file" ]] && emit_args+=(--pr-comments-file "$pr_comments_file")

"$script_dir/emit-handoff.sh" "${emit_args[@]}"
