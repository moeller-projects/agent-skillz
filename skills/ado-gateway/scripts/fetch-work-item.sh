#!/usr/bin/env bash
# fetch-work-item.sh
# Fetches a single Azure DevOps work item via the REST API (GET only).
# Retries transiently failed requests up to five times before emitting an error.
set -euo pipefail

org="${1:?org required}"
project="${2:?project required}"
work_item_id="${3:?work item id required}"
base_url="${4:-https://dev.azure.com}"

"$(dirname "$0")/ensure-env.sh" --require-pat

url="$base_url/$org/$project/_apis/wit/workitems/$work_item_id?api-version=7.1"

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
  echo "message: Failed to fetch work item $work_item_id from $org/$project after bounded retries." >&2
  echo "recovery: Check AZURE_DEVOPS_PAT, organization, project, and network connectivity." >&2
  exit 1
}

printf '%s' "$response"
