#!/usr/bin/env bash
set -euo pipefail

spec_file="${1:?spec file required}"
required=(
  "^# .+"
  "^Version:"
  "^Risk Tier:"
  "^## Overview"
  "^## Scope"
  "^## Assumptions"
  "^## Functional Requirements"
  "^## Non-Functional Requirements"
  "^## Acceptance Criteria"
  "^## Review Context"
  "^## Open Questions"
)

missing=()
out_of_order=()
last_line=0
for pattern in "${required[@]}"; do
  match_line="$(grep -nE "$pattern" "$spec_file" | head -n 1 | cut -d: -f1 || true)"
  if [[ -z "$match_line" ]]; then
    missing+=("$pattern")
    continue
  fi
  if [[ "$match_line" -lt "$last_line" ]]; then
    out_of_order+=("$pattern")
  fi
  last_line="$match_line"
done

jq -n \
  --argjson missing "$(printf '%s\n' "${missing[@]:-}" | jq -R . | jq -s 'map(select(length > 0))')" \
  --argjson out_of_order "$(printf '%s\n' "${out_of_order[@]:-}" | jq -R . | jq -s 'map(select(length > 0))')" \
  '{pass: ((($missing | length) == 0) and (($out_of_order | length) == 0)), missing: $missing, out_of_order: $out_of_order}'
if [[ ${#missing[@]} -gt 0 || ${#out_of_order[@]} -gt 0 ]]; then
  exit 1
fi
