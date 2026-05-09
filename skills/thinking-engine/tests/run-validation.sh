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
pass "thinking-engine required files exist"

cat <<'EOF' | bash "$validator" > /dev/null
problem:
- Need a rollout plan for adding real-time notifications.

assumptions:
- WebSocket infrastructure can be reused.

options:
1. Extend the existing WebSocket service.
2. Use a managed push service.

recommendation:
- Start with the managed push service to reduce operational load.

next:
- Confirm notification volume and budget constraints.
EOF
pass "valid thinking output passes"

if cat <<'EOF' | bash "$validator" > /dev/null 2> "$tmp_dir/invalid.err"
problem:
- Need a rollout plan for adding real-time notifications.

assumptions:
- WebSocket infrastructure can be reused.

options:
1. Extend the existing WebSocket service.

next:
- Confirm notification volume and budget constraints.
EOF
then
  fail "invalid thinking output unexpectedly passed"
fi
grep -q 'missing section: recommendation:' "$tmp_dir/invalid.err" || fail "missing recommendation failure not reported"
pass "validator rejects incomplete thinking output"

printf '\nThinking Engine validation completed successfully.\n'
