#!/usr/bin/env bash
set -euo pipefail

spec_file="${1:?spec file required}"
issues=()
if grep -qiE '\b(should|might|maybe|etc\.)\b' "$spec_file"; then
  issues+=("vague language detected")
fi
if grep -qE '^[[:space:]]*- FR-[0-9]+:.*$' "$spec_file"; then
  :
else
  issues+=("missing FR identifiers")
fi
if grep -qE '^[[:space:]]*- AC-[0-9]+:.*$' "$spec_file"; then
  :
else
  issues+=("missing AC identifiers")
fi

jq -n --argjson issues "$(printf '%s\n' "${issues[@]:-}" | jq -R . | jq -s 'map(select(length > 0))')" '{pass: ($issues | length == 0), issues: $issues}'
if [[ ${#issues[@]} -gt 0 ]]; then
  exit 1
fi
