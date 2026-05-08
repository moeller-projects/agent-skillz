#!/usr/bin/env bash
# create-pr-comment.sh
# Creates an Azure DevOps PR comment thread or replies to an existing thread.
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
source "$script_dir/write-guard.sh"
"$script_dir/ensure-env.sh"

mode="thread"
pull_request_url=""
organization="${ADO_ORGANIZATION:-}"
project="${ADO_PROJECT:-}"
repository_id="${ADO_REPOSITORY_ID:-}"
pull_request_id="${ADO_PULL_REQUEST_ID:-}"
thread_id=""
content=""
file_path=""
side="right"
line=""
execute="false"
confirm_write=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) mode="$2"; shift 2 ;;
    --pull-request-url) pull_request_url="$2"; shift 2 ;;
    --organization) organization="$2"; shift 2 ;;
    --project) project="$2"; shift 2 ;;
    --repository-id) repository_id="$2"; shift 2 ;;
    --pull-request-id) pull_request_id="$2"; shift 2 ;;
    --thread-id) thread_id="$2"; shift 2 ;;
    --content) content="$2"; shift 2 ;;
    --file-path) file_path="$2"; shift 2 ;;
    --side) side="$2"; shift 2 ;;
    --line) line="$2"; shift 2 ;;
    --execute) execute="true"; shift ;;
    --confirm-write) confirm_write="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ -n "$pull_request_url" ]]; then
  parsed="$($script_dir/parse-pr-url.sh "$pull_request_url")"
  [[ -z "$organization" ]] && organization="$(jq -r '.organization' <<<"$parsed")"
  [[ -z "$project" ]] && project="$(jq -r '.project' <<<"$parsed")"
  [[ -z "$repository_id" ]] && repository_id="$(jq -r '.repository_id' <<<"$parsed")"
  [[ -z "$pull_request_id" ]] && pull_request_id="$(jq -r '.pull_request_id' <<<"$parsed")"
fi

if [[ "$mode" != "thread" && "$mode" != "reply" ]]; then
  echo "ERROR:" >&2
  echo "code: PARSE_FAILED" >&2
  echo "stage: parse" >&2
  echo "message: --mode must be 'thread' or 'reply'." >&2
  echo "recovery: Use --mode thread for a new thread or --mode reply for an existing thread." >&2
  exit 1
fi
if [[ "$side" != "left" && "$side" != "right" ]]; then
  echo "ERROR:" >&2
  echo "code: PARSE_FAILED" >&2
  echo "stage: parse" >&2
  echo "message: --side must be 'left' or 'right'." >&2
  echo "recovery: Omit --side for right-side comments or pass left/right." >&2
  exit 1
fi

missing=()
[[ -z "$organization" ]] && missing+=(organization)
[[ -z "$project" ]] && missing+=(project)
[[ -z "$repository_id" ]] && missing+=(repository_id)
[[ -z "$pull_request_id" ]] && missing+=(pull_request_id)
[[ -z "$content" ]] && missing+=(content)
[[ "$mode" == "reply" && -z "$thread_id" ]] && missing+=(thread_id)
if [[ ${#missing[@]} -gt 0 ]]; then
  echo "BLOCKER:" >&2
  echo "code: MISSING_INPUT" >&2
  echo "required_input:" >&2
  for item in "${missing[@]}"; do echo "- $item" >&2; done
  echo "next_question: Provide the missing values before creating the PR comment." >&2
  exit 1
fi

require_write_confirmation "$execute" "$confirm_write"
[[ "$execute" == "true" ]] && "$script_dir/ensure-env.sh" --require-pat

tmp_body="$(mktemp)"
trap 'rm -f "$tmp_body"' EXIT

base="https://dev.azure.com/$organization/$project/_apis/git/repositories/$repository_id/pullRequests/$pull_request_id/threads"
if [[ "$mode" == "reply" ]]; then
  url="$base/$thread_id/comments?api-version=7.1"
  action_type="reply-pr-comment"
  jq -n --arg content "$content" '{content:$content, commentType:1}' > "$tmp_body"
else
  url="$base?api-version=7.1"
  action_type="create-pr-comment-thread"
  if [[ -n "$file_path" ]]; then
    if [[ -z "$line" ]]; then
      echo "BLOCKER:" >&2
      echo "code: MISSING_INPUT" >&2
      echo "required_input:" >&2
      echo "- line" >&2
      echo "next_question: Provide --line for inline PR comments or omit --file-path for a general thread." >&2
      exit 1
    fi
    if [[ "$side" == "right" ]]; then
      jq -n --arg content "$content" --arg filePath "$file_path" --argjson line "$line" '{comments:[{parentCommentId:0,content:$content,commentType:1}],status:"active",threadContext:{filePath:$filePath,rightFileStart:{line:$line,offset:1},rightFileEnd:{line:$line,offset:1}}}' > "$tmp_body"
    else
      jq -n --arg content "$content" --arg filePath "$file_path" --argjson line "$line" '{comments:[{parentCommentId:0,content:$content,commentType:1}],status:"active",threadContext:{filePath:$filePath,leftFileStart:{line:$line,offset:1},leftFileEnd:{line:$line,offset:1}}}' > "$tmp_body"
    fi
  else
    jq -n --arg content "$content" '{comments:[{parentCommentId:0,content:$content,commentType:1}],status:"active"}' > "$tmp_body"
  fi
fi

if [[ "$execute" != "true" ]]; then
  jq -n \
    --arg action_type "$action_type" \
    --arg method "POST" \
    --arg url "$url" \
    --arg risk "high" \
    --argjson body "$(cat "$tmp_body")" \
    '{action_type:$action_type,dry_run:true,requires_confirmation:true,risk:$risk,method:$method,url:$url,content_type:"application/json",required_scopes:["Code: Read & write","OAuth: vso.code_write"],body:$body}'
  exit 0
fi

curl_json_write "POST" "application/json" "$url" "$tmp_body" "$action_type"
