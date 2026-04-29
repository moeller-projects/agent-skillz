#!/usr/bin/env bash
set -euo pipefail

require_pat="false"
for arg in "$@"; do
  case "$arg" in
    --require-pat) require_pat="true" ;;
  esac
done

missing=()
for cmd in curl jq python3; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    missing+=("$cmd")
  fi
done

if [[ "$require_pat" == "true" && -z "${AZURE_DEVOPS_PAT:-}" ]]; then
  echo "BLOCKER:" >&2
  echo "code: MISSING_AUTH" >&2
  echo "required_input:" >&2
  echo "- AZURE_DEVOPS_PAT" >&2
  echo "next_question: Provide an Azure DevOps PAT through AZURE_DEVOPS_PAT and retry." >&2
  exit 1
fi

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "BLOCKER:" >&2
  echo "code: MISSING_INPUT" >&2
  echo "required_input:" >&2
  for item in "${missing[@]}"; do
    echo "- ${item}" >&2
  done
  echo "next_question: Install the missing command dependencies and retry." >&2
  exit 1
fi
