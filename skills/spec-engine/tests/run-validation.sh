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
grep -q 'normalized ado-gateway handoff' "$skill_dir/SKILL.md" || fail "spec-engine overlap guard missing"
pass "spec-engine required files and overlap guard exist"

cat <<'EOF' | bash "$validator" > /dev/null
spec:
- goal: Let customers reset their password securely.
- scope:
  - IN: self-service password reset for existing accounts
  - OUT: account recovery by phone support
- requirements:
  - REQ-01: The system sends a reset link to the verified account email address.
- acceptance_criteria:
  - AC-01 (REQ-01): GIVEN a verified account WHEN the user requests a reset THEN the system emails a one-time reset link.

quality_gates:
- [ ] Security review completed

open_questions:
- OQ-01: Which email provider owns the send quota? — owner: platform-team — due: sprint-24
EOF
pass "valid spec output passes"

if cat <<'EOF' | bash "$validator" > /dev/null 2> "$tmp_dir/invalid.err"
spec:
- goal: Let customers reset their password securely.
- scope:
  - IN: self-service password reset for existing accounts
- requirements:
  - REQ-01: The system should send a reset link to the verified account email address.
- acceptance_criteria:
  - AC-01 (REQ-01): user can reset password

quality_gates:
- [ ] Security review completed

open_questions:
- OQ-01: Which email provider owns the send quota?
EOF
then
  fail "invalid spec output unexpectedly passed"
fi
grep -q 'missing OUT scope entry' "$tmp_dir/invalid.err" || fail "missing OUT scope failure not reported"
pass "validator rejects incomplete or vague spec output"

printf '\nSpec Engine validation completed successfully.\n'
