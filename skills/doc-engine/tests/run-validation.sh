#!/usr/bin/env bash
set -euo pipefail

skill_dir="$(cd "$(dirname "$0")/.." && pwd)"
validator="$skill_dir/scripts/validate-output.sh"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

for required in "$validator" "$skill_dir/assets/templates/output.md" "$skill_dir/tests/validation-checklist.md"; do
  [[ -f "$required" ]] || fail "missing $(basename "$required")"
done
grep -q 'explicit approval' "$skill_dir/SKILL.md" || fail "overwrite approval gate missing"
pass "doc-engine required files and approval gate exist"

cat <<'EOF' | bash "$validator" > /dev/null
doc:
- purpose: Help contributors run the skill build workflow correctly.
- audience: engineer unfamiliar with the repository layout.
- structure:
  1. Setup — install dependencies and prerequisites
  2. Validation — explain validation and packaging commands

changes:
- README.md — add setup and validation workflow notes

gaps:
- Need confirmed CI screenshots for the release section
EOF
pass "valid doc output passes"

if cat <<'EOF' | bash "$validator" > /dev/null 2> "$tmp_dir/invalid.err"
doc:
- purpose: Help contributors run the skill build workflow correctly.
- structure:
  1. Setup — install dependencies and prerequisites

changes:
- README.md — add setup notes

gaps:
- None
EOF
then
  fail "invalid doc output unexpectedly passed"
fi
grep -q 'missing doc audience' "$tmp_dir/invalid.err" || fail "missing audience failure not reported"
pass "validator rejects incomplete doc output"

printf '\nDoc Engine validation completed successfully.\n'
