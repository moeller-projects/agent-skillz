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
  1. Setup [tutorial] — install dependencies and prerequisites
  2. Validation [how-to] — explain validation and packaging commands
- format:
  - type: markdown
  - reason: repository-maintained developer documentation
- artifact:
  - README.md

changes:
- README.md — add setup and validation workflow notes

gaps:
- Need confirmed CI screenshots for the release section
EOF
pass "valid doc output passes"

if cat <<'EOF' | bash "$validator" > "$tmp_dir/untagged.out" 2>/dev/null
doc:
- purpose: Help contributors run the skill build workflow correctly.
- audience: engineer unfamiliar with the repository layout.
- structure:
  1. Setup — install dependencies and prerequisites
  2. Validation — explain validation and packaging commands

changes:
- README.md — add setup notes

gaps:
- None
EOF
then
  fail "untagged structure entries unexpectedly passed"
fi
grep -q 'structure entry missing valid mode tag' "$tmp_dir/untagged.out" || fail "missing mode tag failure not reported"
pass "validator rejects structure entries without mode tags"

if cat <<'EOF' | bash "$validator" > "$tmp_dir/invalid.out" 2>/dev/null
doc:
- purpose: Help contributors run the skill build workflow correctly.
- structure:
  1. Setup [tutorial] — install dependencies and prerequisites

changes:
- README.md — add setup notes

gaps:
- None
EOF
then
  fail "invalid doc output unexpectedly passed"
fi
grep -q 'missing doc audience' "$tmp_dir/invalid.out" || fail "missing audience failure not reported"
pass "validator rejects incomplete doc output"

if cat <<'EOF' | bash "$validator" > /dev/null
doc:
- purpose: Help stakeholders review progress and risks.
- audience: product leadership, unfamiliar with repo implementation details.
- structure:
  1. Executive summary [explanation] — concise status for stakeholders
  2. Risks and blockers [reference] — current issues and mitigation
- format:
  - type: html
  - reason: read-only stakeholder communication artifact
- artifact:
  - weekly-engineering-update.html

changes:
- weekly-engineering-update.html — add standalone stakeholder report

gaps:
- None
EOF
then
  pass "validator accepts html output contract"
else
  fail "html output contract rejected"
fi

printf '\nDoc Engine validation completed successfully.\n'
