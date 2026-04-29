#!/usr/bin/env bash
set -euo pipefail

spec_file="${1:?spec file required}"
base_dir="$(dirname "$0")"

structure_json="$($base_dir/policies/10-structure.sh "$spec_file")"
style_json="$($base_dir/policies/20-requirements-style.sh "$spec_file")"
security_json="$($base_dir/policies/30-security-redactions.sh "$spec_file")"

structure_pass="$(jq -r '.pass' <<<"$structure_json")"
style_pass="$(jq -r '.pass' <<<"$style_json")"
security_pass="$(jq -r '.pass' <<<"$security_json")"

overall="pass"
if [[ "$structure_pass" != "true" || "$style_pass" != "true" || "$security_pass" != "true" ]]; then
  overall="fail"
fi

jq -n \
  --arg overall "$overall" \
  --argjson structure "$structure_json" \
  --argjson style "$style_json" \
  --argjson security "$security_json" \
  '{validation: $overall, gates: {structure: $structure, style: $style, security: $security}}'

if [[ "$overall" != "pass" ]]; then
  exit 1
fi
