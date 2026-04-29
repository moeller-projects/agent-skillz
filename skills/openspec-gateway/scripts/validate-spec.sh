#!/usr/bin/env bash
set -euo pipefail

spec_file="${1:?spec file required}"
base_dir="$(cd "$(dirname "$0")" && pwd)"

run_gate() {
  local output status
  set +e
  output="$("$@")"
  status=$?
  set -e
  printf '%s\n%s' "$status" "$output"
}

structure_result="$(run_gate "$base_dir/policies/10-structure.sh" "$spec_file")"
style_result="$(run_gate "$base_dir/policies/20-requirements-style.sh" "$spec_file")"
security_result="$(run_gate "$base_dir/policies/30-security-redactions.sh" "$spec_file")"

structure_status="$(head -n 1 <<<"$structure_result")"
style_status="$(head -n 1 <<<"$style_result")"
security_status="$(head -n 1 <<<"$security_result")"
structure_json="$(tail -n +2 <<<"$structure_result")"
style_json="$(tail -n +2 <<<"$style_result")"
security_json="$(tail -n +2 <<<"$security_result")"

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

if [[ "$overall" != "pass" || "$structure_status" -ne 0 || "$style_status" -ne 0 || "$security_status" -ne 0 ]]; then
  exit 1
fi
