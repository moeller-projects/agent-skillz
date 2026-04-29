#!/usr/bin/env bash
set -euo pipefail

spec_file="${1:?spec file required}"
required=(
  "^# "
  "^Version:"
  "^Risk Tier:"
  "^## Overview"
  "^## Scope"
  "^## Assumptions"
  "^## Functional Requirements"
  "^## Non-Functional Requirements"
  "^## Acceptance Criteria"
  "^## Open Questions"
)

missing=()
for pattern in "${required[@]}"; do
  if ! grep -qE "$pattern" "$spec_file"; then
    missing+=("$pattern")
  fi
done

jq -n --argjson missing "$(printf '%s\n' "${missing[@]:-}" | jq -R . | jq -s 'map(select(length > 0))')" '{pass: ($missing | length == 0), missing: $missing}'
if [[ ${#missing[@]} -gt 0 ]]; then
  exit 1
fi
