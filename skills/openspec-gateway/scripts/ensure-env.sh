#!/usr/bin/env bash
set -euo pipefail

missing=()
for cmd in jq grep sed; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    missing+=("$cmd")
  fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "BLOCKER:" >&2
  echo "code: MISSING_DEPENDENCIES" >&2
  echo "required_input:" >&2
  for item in "${missing[@]}"; do
    echo "- ${item}" >&2
  done
  echo "next_question: Install the missing command dependencies and retry." >&2
  exit 1
fi
