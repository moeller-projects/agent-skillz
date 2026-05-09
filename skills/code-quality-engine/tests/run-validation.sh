#!/usr/bin/env bash
set -euo pipefail

skill_dir="$(cd "$(dirname "$0")/.." && pwd)"
validator="$skill_dir/scripts/validate-output.sh"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

[[ -f "$validator" ]] || fail "missing validate-output.sh"
pass "validator exists"

cat <<'EOF' | bash "$validator" > /dev/null
findings:
- [critical] src/auth.ts:12 — null dereference on token
  why: crashes request handling
  fix: guard missing token before access
- [high] src/cache.ts:88 — stale entry can leak data
  fix: invalidate cache on write

patch-plan:
1. src/auth.ts — add null guard
2. src/cache.ts — invalidate cache after mutation

risk:
- cache invalidation may reduce hit rate
EOF
pass "sorted findings pass validation"

if cat <<'EOF' | bash "$validator" > /dev/null 2> "$tmp_dir/invalid.err"
findings:
- [low] src/log.ts:5 — message is noisy
  fix: lower log level
- [critical] src/auth.ts:12 — null dereference on token
  fix: guard missing token before access

patch-plan:
1. src/log.ts — lower log level
2. src/auth.ts — add null guard

risk:
- minor churn
EOF
then
  fail "unsorted findings unexpectedly passed"
fi
grep -q 'sorted by severity' "$tmp_dir/invalid.err" || fail "severity ordering failure not reported"
pass "severity ordering is enforced"

printf '\nCode Quality Engine validation completed successfully.\n'
