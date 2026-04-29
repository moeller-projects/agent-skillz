#!/usr/bin/env bash
set -euo pipefail

spec_file="${1:?spec file required}"
issues=()
if grep -qiE 'Bearer[[:space:]]+[A-Za-z0-9._-]+' "$spec_file"; then
  issues+=("bearer token detected")
fi
if grep -qE 'AZURE_DEVOPS_PAT|ghp_[A-Za-z0-9]+' "$spec_file"; then
  issues+=("secret-like token detected")
fi

jq -n --argjson issues "$(printf '%s\n' "${issues[@]:-}" | jq -R . | jq -s 'map(select(length > 0))')" '{pass: ($issues | length == 0), issues: $issues}'
if [[ ${#issues[@]} -gt 0 ]]; then
  exit 1
fi
