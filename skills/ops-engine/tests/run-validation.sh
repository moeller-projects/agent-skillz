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
risk:
- medium likelihood / high impact — rollout can break ingress routing

plan:
1. Apply the ingress manifest in staging.

checks:
- kubectl apply --dry-run=server -f k8s/ingress.yaml

rollback:
- Reapply the previous ingress manifest from release artifact ingress-prev.yaml

security:
- human approval required before production rollout
EOF
pass "valid ops output passes"

if cat <<'EOF' | bash "$validator" > /dev/null 2> "$tmp_dir/invalid.err"
risk:
- medium likelihood / high impact — rollout can break ingress routing

plan:
1. Deploy to production immediately.

checks:
- kubectl apply --dry-run=server -f k8s/ingress.yaml

rollback:
- Reapply the previous ingress manifest from release artifact ingress-prev.yaml

security:
- verify TLS secret exists
EOF
then
  fail "production plan without approval unexpectedly passed"
fi
grep -qi 'human approval gate' "$tmp_dir/invalid.err" || fail "production approval failure not reported"
pass "validator rejects production steps without approval"

printf '\nOps Engine validation completed successfully.\n'
