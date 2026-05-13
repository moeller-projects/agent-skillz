#!/usr/bin/env bash
# create-work-item-comment.sh
# Creates an Azure DevOps work item comment through a dry-run-first guarded POST.
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
source "$script_dir/write-guard.sh"
"$script_dir/ensure-env.sh"

organization="${ADO_ORGANIZATION:-}"
project="${ADO_PROJECT:-}"
work_item_id=""
text=""
execute="false"
confirm_write=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --organization) organization="$2"; shift 2 ;;
    --project) project="$2"; shift 2 ;;
    --work-item-id) work_item_id="$2"; shift 2 ;;
    --text) text="$2"; shift 2 ;;
    --execute) execute="true"; shift ;;
    --confirm-write) confirm_write="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

missing=()
[[ -z "$organization" ]] && missing+=(organization)
[[ -z "$project" ]] && missing+=(project)
[[ -z "$work_item_id" ]] && missing+=(work_item_id)
[[ -z "$text" ]] && missing+=(text)
if [[ ${#missing[@]} -gt 0 ]]; then
  echo "BLOCKER:" >&2
  echo "code: MISSING_INPUT" >&2
  echo "required_input:" >&2
  for item in "${missing[@]}"; do echo "- $item" >&2; done
  echo "next_question: Provide the missing values before creating a work item comment." >&2
  exit 1
fi

if [[ ! "$work_item_id" =~ ^[0-9]+$ ]]; then
  echo "ERROR:" >&2
  echo "code: PARSE_FAILED" >&2
  echo "stage: parse" >&2
  echo "message: --work-item-id must be an integer." >&2
  echo "recovery: Provide a numeric work item id." >&2
  exit 1
fi

require_write_confirmation "$execute" "$confirm_write"
[[ "$execute" == "true" ]] && "$script_dir/ensure-env.sh" --require-pat

url="https://dev.azure.com/$organization/$project/_apis/wit/workItems/$work_item_id/comments?api-version=7.1-preview.4"
tmp_body="$(mktemp)"
trap 'rm -f "$tmp_body"' EXIT

jq -n --arg text "$text" '{text:$text}' > "$tmp_body"

if [[ "$execute" != "true" ]]; then
  jq -n \
    --arg action_type "create-work-item-comment" \
    --arg method "POST" \
    --arg url "$url" \
    --arg risk "high" \
    --argjson body "$(cat "$tmp_body")" \
    '{action_type:$action_type,dry_run:true,requires_confirmation:true,risk:$risk,method:$method,url:$url,content_type:"application/json",required_scopes:["Work Items: Read & write","OAuth: vso.work_write"],body:$body}'
  exit 0
fi

curl_json_write "POST" "application/json" "$url" "$tmp_body" "create work item comment"
