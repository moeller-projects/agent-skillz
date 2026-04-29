#!/usr/bin/env bash
set -euo pipefail

spec_file="${1:?spec file required}"

if [[ ! -r "$spec_file" ]]; then
  jq -n --arg spec_file "$spec_file" '{pass: false, missing: [], out_of_order: [], error: ("spec file not readable: " + $spec_file)}'
  exit 1
fi

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
  set +e
  match_output="$(grep -nEm1 "$pattern" "$spec_file")"
  grep_status=$?
  set -e

  if [[ "$grep_status" -eq 1 ]]; then
    missing+=("$pattern")
    continue
  fi
  if [[ "$grep_status" -ne 0 ]]; then
    jq -n --arg pattern "$pattern" '{pass: false, missing: [], out_of_order: [], error: ("failed to evaluate pattern: " + $pattern)}'
    exit 1
  fi

  match_line="${match_output%%:*}"
  if [[ ! "$match_line" =~ ^[0-9]+$ ]]; then
    jq -n --arg pattern "$pattern" '{pass: false, missing: [], out_of_order: [], error: ("invalid match output for pattern: " + $pattern)}'
    exit 1
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
