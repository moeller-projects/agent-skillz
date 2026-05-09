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
pass "test-engine required files exist"

cat <<'EOF' | bash "$validator" > /dev/null
test-plan:
1. Add unit tests for valid and invalid discount codes.

coverage-gaps:
- Browser checkout E2E is blocked until staging credentials are available.

cases:
- GIVEN a valid discount code WHEN checkout is submitted THEN the order total is reduced.
- GIVEN an expired discount code WHEN checkout is submitted THEN the API returns a validation error.

risk:
- Staging-only tax logic still needs manual verification
EOF
pass "valid test output passes"

if cat <<'EOF' | bash "$validator" > /dev/null 2> "$tmp_dir/invalid.err"
test-plan:
1. Add unit tests for valid and invalid discount codes.

coverage-gaps:
- Browser checkout E2E is blocked until staging credentials are available.

cases:
- GIVEN a valid discount code WHEN checkout is submitted.

risk:
- Staging-only tax logic still needs manual verification
EOF
then
  fail "invalid test output unexpectedly passed"
fi
grep -qi 'GIVEN/WHEN/THEN' "$tmp_dir/invalid.err" || fail "case format failure not reported"
pass "validator rejects incomplete test cases"

printf '\nTest Engine validation completed successfully.\n'
