#!/usr/bin/env bash
set -euo pipefail

org="${1:?org required}"
project="${2:?project required}"
work_item_id="${3:?work item id required}"
base_url="${4:-https://dev.azure.com}"

"$(dirname "$0")/ensure-env.sh" --require-pat

url="$base_url/$org/$project/_apis/wit/workitems/$work_item_id?api-version=7.1"
curl -fsS   -u ":${AZURE_DEVOPS_PAT}"   -H "Accept: application/json"   "$url"
