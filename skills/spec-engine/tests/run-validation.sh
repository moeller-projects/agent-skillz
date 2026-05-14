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
grep -q 'ado-gateway handoff JSON' "$skill_dir/SKILL.md" || fail "spec-engine ado-gateway handoff use-when entry missing"
grep -q 'pure OpenSpec governance with no spec-authoring step' "$skill_dir/SKILL.md" || fail "spec-engine OpenSpec governance avoid-when entry missing"
grep -q 'output_format=openspec' "$skill_dir/SKILL.md" || fail "spec-engine openspec output_format workflow entry missing"
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

risk_tier: Medium

quality_gates:
- [ ] Security review completed

open_questions:
- OQ-01: Which email provider owns the send quota? — owner: platform-team — due: sprint-24
EOF
pass "valid spec output passes"

if cat <<'EOF' | bash "$validator" > "$tmp_dir/invalid.out" 2> "$tmp_dir/invalid.err"
spec:
- goal: Let customers reset their password securely.
- scope:
  - IN: self-service password reset for existing accounts
- requirements:
  - REQ-01: The system should, where appropriate, send a reset link to the verified account email address.
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

if cat <<'EOF' | bash "$validator" > "$tmp_dir/missing-req.out" 2> "$tmp_dir/missing-req.err"
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

if cat <<'EOF' | bash "$validator" > "$tmp_dir/duplicate-req.out" 2> "$tmp_dir/duplicate-req.err"
spec:
- goal: Let customers reset their password securely.
- scope:
  - IN: self-service password reset for existing accounts
  - OUT: account recovery by phone support
- requirements:
  - REQ-01: The system sends a reset link to the verified account email address.
  - REQ-01: The reset link expires after 15 minutes.
- acceptance_criteria:
  - AC-01 (REQ-01): GIVEN a verified account WHEN the user requests a reset THEN the system emails a one-time reset link.

quality_gates:
- [ ] Security review completed

open_questions:
- OQ-01: Which email provider owns the send quota? — owner: platform-team — due: sprint-24
EOF
then
  fail "duplicate REQ identifiers unexpectedly passed"
fi
grep -q 'requirements must use unique REQ-XX identifiers' "$tmp_dir/duplicate-req.out" || fail "duplicate REQ failure not reported"
pass "validator rejects duplicate REQ identifiers"

if cat <<'EOF' | bash "$validator" > "$tmp_dir/invalid-risk-tier.out" 2> "$tmp_dir/invalid-risk-tier.err"
spec:
- goal: Let customers reset their password securely.
- scope:
  - IN: self-service password reset for existing accounts
  - OUT: account recovery by phone support
- requirements:
  - REQ-01: The system sends a reset link to the verified account email address.
- acceptance_criteria:
  - AC-01 (REQ-01): GIVEN a verified account WHEN the user requests a reset THEN the system emails a one-time reset link.

risk_tier: Unknown

quality_gates:
- [ ] Security review completed

open_questions:
- OQ-01: Which email provider owns the send quota? — owner: platform-team — due: sprint-24
EOF
then
  fail "invalid risk_tier value unexpectedly passed"
fi
grep -q 'risk_tier must be one of' "$tmp_dir/invalid-risk-tier.out" || fail "invalid risk_tier failure not reported"
pass "validator rejects invalid risk_tier values"

cat <<'EOF' | bash "$validator" > /dev/null
output_format: openspec
openspec_proposal:
  path: proposals/
  change_path: openspec/changes/add-password-reset-flow/
  metadata_file: .openspec.yaml
  proposal_file: proposal.md
  delta_spec_files:
  - specs/auth/spec.md

proposal.md:
## Why
Reset flows are required for account recovery.
## What Changes
- Add reset-link capability with expiring token validation.
## Capabilities
- New: auth-reset-flow
## Impact
- Auth service, email service, and integration tests.

specs/auth/spec.md:
## ADDED Requirements
### Requirement: Password reset link delivery
The system MUST deliver reset links to verified account emails.

#### Scenario: Reset link sent
- **WHEN** a verified user requests password reset
- **THEN** the system sends a reset email with a one-time link
EOF
pass "valid openspec output passes"

if cat <<'EOF' | bash "$validator" > "$tmp_dir/openspec-invalid.out" 2> "$tmp_dir/openspec-invalid.err"
output_format: openspec
openspec_proposal:
  path: proposals/
  change_path: openspec/changes/add-password-reset-flow/
  metadata_file: change.yaml
  proposal_file: proposal.md
  delta_spec_files:
  - specs/auth/spec.md

proposal.md:
## Why
Reset flows are required for account recovery.
## What Changes
- Add reset-link capability with expiring token validation.

specs/auth/spec.md:
### Requirement: Password reset link delivery
The system should deliver reset links to verified account emails.
EOF
then
  fail "invalid openspec output unexpectedly passed"
fi
grep -q 'metadata_file: .openspec.yaml' "$tmp_dir/openspec-invalid.out" || fail "openspec metadata_file failure not reported"
grep -q 'must not emit change.yaml' "$tmp_dir/openspec-invalid.out" || fail "openspec change.yaml failure not reported"
grep -q 'proposal.md missing section: ## Capabilities' "$tmp_dir/openspec-invalid.out" || fail "openspec capabilities section failure not reported"
grep -q 'delta spec must include at least one delta section header' "$tmp_dir/openspec-invalid.out" || fail "openspec delta header failure not reported"
grep -q 'must include at least one #### Scenario' "$tmp_dir/openspec-invalid.out" || fail "openspec scenario failure not reported"
pass "validator rejects invalid openspec output"

printf '\nSpec Engine validation completed successfully.\n'
