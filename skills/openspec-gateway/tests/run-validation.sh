#!/usr/bin/env bash
set -euo pipefail

skill_dir="$(cd "$(dirname "$0")/.." && pwd)"
scripts_dir="$skill_dir/scripts"
examples_dir="$skill_dir/assets/examples"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq is required for validation"

for script in ensure-env.sh score-spec.sh spec-from-handoff.sh spec-from-input.sh validate-risk-tier.sh validate-spec.sh emit-artifact.sh; do
  [[ -f "$scripts_dir/$script" ]] || fail "missing $script"
done
pass "required openspec scripts exist"

[[ "$(jq -r '.source.work_item_id | type' "$examples_dir/input-handoff.json")" == "number" ]] || fail "source.work_item_id must be numeric"
[[ "$(jq -r '.work_item.id | type' "$examples_dir/input-handoff.json")" == "number" ]] || fail "work_item.id must be numeric"
pass "handoff example keeps numeric ids"

bash "$scripts_dir/score-spec.sh" "$examples_dir/generated-spec.md" > "$tmp_dir/score.json"
artifact_score="$(jq -c '.quality' "$examples_dir/artifact.json")"
generated_score="$(jq -c '.' "$tmp_dir/score.json")"
[[ "$artifact_score" == "$generated_score" ]] || fail "artifact quality example does not match score-spec.sh output"
pass "artifact example matches deterministic score output"

RISK_TIER=Medium bash "$scripts_dir/spec-from-handoff.sh" "$examples_dir/input-handoff.json" "$tmp_dir/from-handoff.md" > /dev/null
grep -q '^# Checkout supports discount codes' "$tmp_dir/from-handoff.md" || fail "spec-from-handoff did not render expected title"
bash "$scripts_dir/spec-from-input.sh" --title "Example" --description "Example body" --risk-tier Medium --output "$tmp_dir/from-input.md" > /dev/null
grep -q '^Version: 0.1.0' "$tmp_dir/from-input.md" || fail "spec-from-input did not render expected version"
pass "spec generation scripts render deterministic output"

printf '\nOpenSpec Gateway validation completed successfully.\n'
