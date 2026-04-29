#!/usr/bin/env bash
set -euo pipefail

work_item_file=""
pr_comments_file=""
mode=""
organization="${ADO_ORGANIZATION:-}"
project="${ADO_PROJECT:-}"
repository_id="${ADO_REPOSITORY_ID:-}"
pull_request_id="${ADO_PULL_REQUEST_ID:-null}"
work_item_id="${ADO_WORK_ITEM_ID:-null}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --work-item-file) work_item_file="$2"; shift 2 ;;
    --pr-comments-file) pr_comments_file="$2"; shift 2 ;;
    --mode) mode="$2"; shift 2 ;;
    --organization) organization="$2"; shift 2 ;;
    --project) project="$2"; shift 2 ;;
    --repository-id) repository_id="$2"; shift 2 ;;
    --pull-request-id) pull_request_id="$2"; shift 2 ;;
    --work-item-id) work_item_id="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$mode" ]]; then
  if [[ -n "$work_item_file" && -n "$pr_comments_file" ]]; then
    mode="work-item-plus-pr-comments"
  elif [[ -n "$work_item_file" ]]; then
    mode="work-item"
  elif [[ -n "$pr_comments_file" ]]; then
    mode="pr-comments"
  else
    echo "BLOCKER:" >&2
    echo "code: MISSING_INPUT" >&2
    echo "required_input:" >&2
    echo "- --work-item-file and/or --pr-comments-file" >&2
    echo "next_question: Provide normalized input files to emit the handoff contract." >&2
    exit 1
  fi
fi

work_item_json='{}'
pr_comments_json='[]'
missing='[]'
status='pass'
if [[ -n "$work_item_file" ]]; then
  work_item_json="$(cat "$work_item_file")"
fi
if [[ -n "$pr_comments_file" ]]; then
  pr_comments_json="$(jq -c '.comments // .' "$pr_comments_file")"
fi
if [[ "$mode" == "work-item" || "$mode" == "work-item-plus-pr-comments" ]] && [[ -z "$work_item_file" ]]; then
  missing='["work_item"]'
  status='partial'
fi
if [[ "$mode" == "pr-comments" || "$mode" == "work-item-plus-pr-comments" ]] && [[ -z "$pr_comments_file" ]]; then
  missing="$(jq -cn --argjson existing "$missing" '$existing + ["pr_comments"]')"
  status='partial'
fi

jq -n \
  --arg mode "$mode" \
  --arg organization "$organization" \
  --arg project "$project" \
  --arg repository_id "$repository_id" \
  --arg producer "ado-gateway" \
  --arg consumer "openspec-gateway" \
  --arg status "$status" \
  --argjson work_item_id "${work_item_id}" \
  --argjson pull_request_id "${pull_request_id}" \
  --argjson work_item "$work_item_json" \
  --argjson pr_comments "$pr_comments_json" \
  --argjson missing_fields "$missing" \
  '{
    contract_version: "1.0.0",
    producer: $producer,
    consumer: $consumer,
    artifact_type: "ado-normalized",
    mode: $mode,
    source: {
      platform: "azure-devops",
      organization: $organization,
      project: $project,
      repository_id: $repository_id,
      pull_request_id: $pull_request_id,
      work_item_id: $work_item_id,
      read_only: true
    },
    normalization: {
      status: $status,
      missing_fields: $missing_fields,
      warnings: [],
      html_stripped: true,
      secret_redactions_applied: true
    },
    work_item: $work_item,
    pr_comments: $pr_comments
  }'
