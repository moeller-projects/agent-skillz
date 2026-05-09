#!/usr/bin/env bash
# create-work-item.sh
# Creates an Azure DevOps work item through a dry-run-first guarded POST.
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
source "$script_dir/write-guard.sh"
"$script_dir/ensure-env.sh"

organization="${ADO_ORGANIZATION:-}"
project="${ADO_PROJECT:-}"
type=""
title=""
description=""
fields_json="{}"
execute="false"
confirm_write=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --organization) organization="$2"; shift 2 ;;
    --project) project="$2"; shift 2 ;;
    --type) type="$2"; shift 2 ;;
    --title) title="$2"; shift 2 ;;
    --description) description="$2"; shift 2 ;;
    --fields-json) fields_json="$2"; shift 2 ;;
    --execute) execute="true"; shift ;;
    --confirm-write) confirm_write="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

missing=()
[[ -z "$organization" ]] && missing+=(organization)
[[ -z "$project" ]] && missing+=(project)
[[ -z "$type" ]] && missing+=(type)
[[ -z "$title" ]] && missing+=(title)
if [[ ${#missing[@]} -gt 0 ]]; then
  echo "BLOCKER:" >&2
  echo "code: MISSING_INPUT" >&2
  echo "required_input:" >&2
  for item in "${missing[@]}"; do echo "- $item" >&2; done
  echo "next_question: Provide the missing values before creating a work item." >&2
  exit 1
fi

if ! jq -e 'type == "object"' <<<"$fields_json" >/dev/null; then
  echo "ERROR:" >&2
  echo "code: PARSE_FAILED" >&2
  echo "stage: parse" >&2
  echo "message: --fields-json must be a JSON object." >&2
  echo "recovery: Pass fields as '{\"System.Tags\":\"tag\"}' or omit --fields-json." >&2
  exit 1
fi

require_write_confirmation "$execute" "$confirm_write"
[[ "$execute" == "true" ]] && "$script_dir/ensure-env.sh" --require-pat

type_encoded="$(jq -rn --arg value "$type" '$value|@uri')"
url="https://dev.azure.com/$organization/$project/_apis/wit/workitems/\$$type_encoded?api-version=7.1"
tmp_body="$(mktemp)"
trap 'rm -f "$tmp_body"' EXIT

jq -n \
  --arg title "$title" \
  --arg description "$description" \
  --argjson fields "$fields_json" \
  '
  [ {op:"add", path:"/fields/System.Title", value:$title} ]
  + (if $description != "" then [{op:"add", path:"/fields/System.Description", value:$description}] else [] end)
  + ($fields | to_entries | map({op:"add", path:("/fields/" + .key), value:.value}))
  ' > "$tmp_body"

if [[ "$execute" != "true" ]]; then
  jq -n \
    --arg action_type "create-work-item" \
    --arg method "POST" \
    --arg url "$url" \
    --arg risk "high" \
    --argjson body "$(cat "$tmp_body")" \
    '{action_type:$action_type,dry_run:true,requires_confirmation:true,risk:$risk,method:$method,url:$url,content_type:"application/json-patch+json",required_scopes:["Work Items: Read & write","OAuth: vso.work_write"],body:$body}'
  exit 0
fi

curl_json_write "POST" "application/json-patch+json" "$url" "$tmp_body" "create work item"
