#!/usr/bin/env bash
set -euo pipefail

spec_file="${1:?spec file required}"
base_dir="$(cd "$(dirname "$0")" && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

run_gate() {
  local output_file="$1"
  set +e
  shift
  "$@" > "$output_file"
  local status=$?
  set -e
  return "$status"
}

structure_file="$tmp_dir/structure.json"
style_file="$tmp_dir/style.json"
security_file="$tmp_dir/security.json"

structure_status=0
style_status=0
security_status=0

run_gate "$structure_file" "$base_dir/policies/10-structure.sh" "$spec_file" || structure_status=$?
run_gate "$style_file" "$base_dir/policies/20-requirements-style.sh" "$spec_file" || style_status=$?
run_gate "$security_file" "$base_dir/policies/30-security-redactions.sh" "$spec_file" || security_status=$?

structure_json="$(cat "$structure_file")"
style_json="$(cat "$style_file")"
security_json="$(cat "$security_file")"

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
