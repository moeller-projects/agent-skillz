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
pass "delivery-engine required files exist"

# Valid full plan passes
cat <<'EOF' | bash "$validator" > /dev/null
tasks:
- id: T-01
  title: Add reset token table
  estimate: S
  estimate_reliability: high
  depends_on: []
  done_when: Migration runs cleanly in staging.

- id: T-02
  title: Implement reset endpoint
  estimate: M
  estimate_reliability: high
  depends_on: [T-01]
  done_when: Endpoint returns 200 and stores hashed token. Unit tests pass.

dependencies:
- T-01 → T-02: token table must exist before endpoint writes tokens

risks:
- Token expiry not enforced at DB level — low / medium

critical_path:
- T-01 → T-02

unknowns: none

validation:
- Run full reset flow in staging end-to-end.
EOF
pass "valid delivery plan passes"

# Missing done_when fails
if cat <<'EOF' | bash "$validator" > /dev/null 2> "$tmp_dir/no_done.err"
tasks:
- id: T-01
  title: Add reset token table
  estimate: S
  estimate_reliability: high
  depends_on: []

dependencies:
- none

risks:
- none

critical_path:
- T-01

unknowns: none

validation:
- Run staging smoke test.
EOF
then
  fail "plan without done_when unexpectedly passed"
fi
grep -q 'done_when' "$tmp_dir/no_done.err" || fail "missing done_when failure not reported"
pass "validator rejects tasks without done_when"

# Missing unknowns section fails
if cat <<'EOF' | bash "$validator" > /dev/null 2> "$tmp_dir/no_unknowns.err"
tasks:
- id: T-01
  title: Add reset token table
  estimate: S
  estimate_reliability: high
  depends_on: []
  done_when: Migration runs in staging.

dependencies:
- none

risks:
- none

critical_path:
- T-01

validation:
- Run staging smoke test.
EOF
then
  fail "plan without unknowns section unexpectedly passed"
fi
grep -q 'unknowns' "$tmp_dir/no_unknowns.err" || fail "missing unknowns section failure not reported"
pass "validator rejects plans without explicit unknowns section"

# Spike with timebox passes without S/M/L estimate
cat <<'EOF' | bash "$validator" > /dev/null
tasks:
- id: T-01
  title: Spike — audit REST endpoints for GraphQL migration
  timebox: 2 days
  estimate_reliability: low
  depends_on: []
  done_when: Schema candidates documented; U-01 resolved.

dependencies:
- none

risks:
- Schema design has wide blast radius — high / high

critical_path:
- T-01

unknowns:
- U-01: Target GraphQL schema undefined — owner: tech lead

validation:
- Re-run delivery-engine after spike resolves U-01.
EOF
pass "spike with timebox passes without S/M/L estimate"

printf '\nDelivery Engine validation completed successfully.\n'
