#!/usr/bin/env bash
set -euo pipefail

skill_dir="$(cd "$(dirname "$0")/.." && pwd)"

pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

for required in \
  "$skill_dir/SKILL.md" \
  "$skill_dir/README.md" \
  "$skill_dir/metadata.json" \
  "$skill_dir/assets/templates/output.md" \
  "$skill_dir/tests/validation-checklist.md"; do
  [[ -f "$required" ]] || fail "missing $(basename "$required")"
done
pass "required caveman files exist"

grep -q 'Exit caveman mode when user asks for normal mode' "$skill_dir/SKILL.md" || fail "caveman stop behavior is ambiguous"
grep -q 'source of truth' "$skill_dir/SKILL.md" || fail "caveman checklist source-of-truth note missing"
grep -q 'reply returns to normal mode' "$skill_dir/tests/validation-checklist.md" || fail "caveman stop condition missing from checklist"
pass "caveman activation and validation guidance are consistent"

printf '\nCaveman validation completed successfully.\n'
