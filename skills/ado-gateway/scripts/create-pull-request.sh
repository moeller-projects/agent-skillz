#!/usr/bin/env bash
# create-pull-request.sh
# Creates an Azure DevOps pull request through a dry-run-first guarded POST.
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
source "$script_dir/write-guard.sh"
"$script_dir/ensure-env.sh"

organization="${ADO_ORGANIZATION:-}"
project="${ADO_PROJECT:-}"
repository_id="${ADO_REPOSITORY_ID:-}"
source_branch=""
target_branch="main"
title=""
description=""
reviewers_json="[]"
confirm="false"

normalize_ref() {
  local ref="$1"
  if [[ "$ref" == refs/heads/* ]]; then printf '%s' "$ref"; else printf 'refs/heads/%s' "$ref"; fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --organization) organization="$2"; shift 2 ;;
    --project) project="$2"; shift 2 ;;
    --repository-id) repository_id="$2"; shift 2 ;;
    --source-branch) source_branch="$2"; shift 2 ;;
    --target-branch) target_branch="$2"; shift 2 ;;
    --title) title="$2"; shift 2 ;;
    --description) description="$2"; shift 2 ;;
    --reviewers-json) reviewers_json="$2"; shift 2 ;;
    --confirm) confirm="true"; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

missing=()
[[ -z "$organization" ]] && missing+=(organization)
[[ -z "$project" ]] && missing+=(project)
[[ -z "$repository_id" ]] && missing+=(repository_id)
[[ -z "$source_branch" ]] && missing+=(source_branch)
[[ -z "$target_branch" ]] && missing+=(target_branch)
[[ -z "$title" ]] && missing+=(title)
if [[ ${#missing[@]} -gt 0 ]]; then
  echo "BLOCKER:" >&2
  echo "code: MISSING_INPUT" >&2
  echo "required_input:" >&2
  for item in "${missing[@]}"; do echo "- $item" >&2; done
  echo "next_question: Provide the missing values before creating a pull request." >&2
  exit 1
fi

if ! jq -e 'type == "array"' <<<"$reviewers_json" >/dev/null; then
  echo "ERROR:" >&2
  echo "code: PARSE_FAILED" >&2
  echo "stage: parse" >&2
  echo "message: --reviewers-json must be a JSON array." >&2
  echo "recovery: Pass reviewers as '[{\"id\":\"...\"}]' or omit --reviewers-json." >&2
  exit 1
fi

[[ "$confirm" == "true" ]] && "$script_dir/ensure-env.sh" --require-pat

source_ref="$(normalize_ref "$source_branch")"
target_ref="$(normalize_ref "$target_branch")"
url="https://dev.azure.com/$organization/$project/_apis/git/repositories/$repository_id/pullrequests?api-version=7.1"
tmp_body="$(mktemp)"
trap 'rm -f "$tmp_body"' EXIT

jq -n \
  --arg sourceRefName "$source_ref" \
  --arg targetRefName "$target_ref" \
  --arg title "$title" \
  --arg description "$description" \
  --argjson reviewers "$reviewers_json" \
  '{sourceRefName:$sourceRefName,targetRefName:$targetRefName,title:$title,description:$description} + (if ($reviewers|length)>0 then {reviewers:$reviewers} else {} end)' \
  > "$tmp_body"

if [[ "$confirm" != "true" ]]; then
  jq -n \
    --arg action_type "create-pull-request" \
    --arg method "POST" \
    --arg url "$url" \
    --arg risk "high" \
    --argjson body "$(cat "$tmp_body")" \
    '{action_type:$action_type,dry_run:true,requires_confirmation:true,risk:$risk,method:$method,url:$url,content_type:"application/json",required_scopes:["Code: Read & write","OAuth: vso.code_write"],body:$body}'
  exit 0
fi

require_write_confirmation "$confirm"
curl_json_write "POST" "application/json" "$url" "$tmp_body" "create pull request"
