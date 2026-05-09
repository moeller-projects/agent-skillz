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
pass "repo-engine required files exist"

cat <<'EOF' | bash "$validator" > /dev/null
repo_map:
- packages/skill-build — build and packaging logic
- skills — source skills and generated index

entrypoints:
- package.json scripts — validate, build, and pack commands

conventions:
- Skills keep matching versions across metadata and SKILL frontmatter

hotspots:
- skills/INDEX.md — generated output changes whenever skill metadata changes

agent_artifacts:
- onboarding summary for future agents
EOF
pass "valid repo output passes"

if cat <<'EOF' | bash "$validator" > /dev/null 2> "$tmp_dir/invalid.err"
repo_map:
- packages/skill-build

entrypoints:
- package.json scripts

conventions:
- Skills keep matching versions across metadata and SKILL frontmatter

hotspots:
- skills/INDEX.md

agent_artifacts:
- onboarding summary for future agents
EOF
then
  fail "invalid repo output unexpectedly passed"
fi
grep -q 'one-line description' "$tmp_dir/invalid.err" || fail "repo_map description failure not reported"
pass "validator rejects incomplete repo output"

printf '\nRepo Engine validation completed successfully.\n'
