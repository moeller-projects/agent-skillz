#!/usr/bin/env bash
# Shared write guard helpers for ado-gateway write scripts.
set -euo pipefail

ADO_WRITE_CONFIRMATION_TOKEN="I_UNDERSTAND_THIS_WRITES_TO_ADO"

require_write_confirmation() {
  local execute="$1"
  local confirmation="$2"
  if [[ "$execute" != "true" ]]; then
    return 0
  fi
  if [[ "$confirmation" != "$ADO_WRITE_CONFIRMATION_TOKEN" ]]; then
    echo "BLOCKER:" >&2
    echo "code: WRITE_CONFIRMATION_REQUIRED" >&2
    echo "required_input:" >&2
    echo "- --confirm-write $ADO_WRITE_CONFIRMATION_TOKEN" >&2
    echo "next_question: Review the dry-run action plan, then rerun with the explicit confirmation token to execute." >&2
    exit 1
  fi
}

redact_stdin() {
  python3 - <<'PY'
import re, sys
text = sys.stdin.read()
text = re.sub(r'(?i)(Bearer\s+)[A-Za-z0-9._-]+', r'\1[REDACTED]', text)
text = re.sub(r'\b(?:ghp_[A-Za-z0-9]+|AZURE_DEVOPS_PAT|[A-Za-z0-9]{20,}\.[A-Za-z0-9._-]{10,})\b', '[REDACTED]', text)
sys.stdout.write(text)
PY
}

curl_json_write() {
  local method="$1"
  local content_type="$2"
  local url="$3"
  local body_file="$4"
  local label="$5"

  response="$(
    curl -fsS \
      --retry 5 \
      --retry-delay 2 \
      --retry-max-time 60 \
      --retry-all-errors \
      -X "$method" \
      -u ":${AZURE_DEVOPS_PAT}" \
      -H "Accept: application/json" \
      -H "Content-Type: ${content_type}" \
      --data-binary "@$body_file" \
      "$url"
  )" || {
    echo "ERROR:" >&2
    echo "code: WRITE_FAILED" >&2
    echo "stage: write" >&2
    echo "message: Failed to execute ${label} after retries." >&2
    echo "recovery: Check AZURE_DEVOPS_PAT permissions, identifiers, request body, and network connectivity." >&2
    exit 1
  }

  printf '%s' "$response" | redact_stdin
}
