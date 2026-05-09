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
  - REQ-02: The reset link expires after 15 minutes.
- acceptance_criteria:
  - AC-01 (REQ-01): GIVEN a verified account WHEN the user requests a reset THEN the system emails a one-time reset link.
  - AC-02 (REQ-02): GIVEN a valid reset link WHEN 15 minutes elapse THEN the link is rejected.

quality_gates:
- [ ] Security review completed

open_questions:
- OQ-01: Which email provider owns the send quota? — owner: platform-team — due: sprint-24
EOF
pass "valid spec output passes"

if cat <<'EOF' | bash "$validator" > "$tmp_dir/invalid.out" 2>&1
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
grep -q 'missing OUT scope entry' "$tmp_dir/invalid.out" || fail "missing OUT scope failure not reported"
grep -q 'requirements must be testable' "$tmp_dir/invalid.out" || fail "vague requirement failure not reported"
grep -q 'acceptance criteria must use AC-XX (REQ-XX)' "$tmp_dir/invalid.out" || fail "AC traceability failure not reported"
pass "validator rejects incomplete or vague spec output"

if cat <<'EOF' | bash "$validator" > "$tmp_dir/missing-req.out" 2>&1
spec:
- goal: Let customers reset their password securely.
- scope:
  - IN: self-service password reset for existing accounts
  - OUT: account recovery by phone support
- requirements:
  - REQ-01: The system sends a reset link to the verified account email address.
- acceptance_criteria:
  - AC-01 (REQ-99): GIVEN a verified account WHEN the user requests a reset THEN the system emails a one-time reset link.

quality_gates:
- [ ] Security review completed

open_questions:
- OQ-01: Which email provider owns the send quota? — owner: platform-team — due: sprint-24
EOF
then
  fail "AC referencing missing requirement unexpectedly passed"
fi
grep -q 'acceptance criteria must reference an existing REQ-XX item' "$tmp_dir/missing-req.out" || fail "missing REQ reference failure not reported"
pass "validator enforces AC to REQ traceability"

printf '\nSpec Engine validation completed successfully.\n'
