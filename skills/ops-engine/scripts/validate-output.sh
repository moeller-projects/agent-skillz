#!/usr/bin/env bash
# validate-output.sh
# Purpose: Validate Ops Engine output against the risk/plan/checks/rollback/security contract.
# Inputs: Contract text on stdin.
# Outputs: "OK" on stdout when valid; validation errors on stdout when invalid.
# Side effects: None.
set -euo pipefail

INPUT=$(cat)
ERRORS=()

# Check required sections
for SECTION in "^risk:" "^plan:" "^checks:" "^rollback:" "^security:"; do
  if ! echo "$INPUT" | grep -qE "$SECTION"; then
    ERRORS+=("missing section: ${SECTION//^/}")
  fi
done

# Check that ABORT is present if plan contains BLOCKED
if echo "$INPUT" | grep -qiE "BLOCKED"; then
  if ! echo "$INPUT" | grep -qiE "ABORT"; then
    ERRORS+=("plan is BLOCKED but no ABORT statement found")
  fi
fi

# Check that human approval is mentioned when production is referenced
if echo "$INPUT" | grep -qiE "production"; then
  if ! echo "$INPUT" | grep -qiE "human approval|approval required"; then
    ERRORS+=("production step found but no human approval gate")
  fi
fi

if [ ${#ERRORS[@]} -gt 0 ]; then
  echo "INVALID output:"
  for ERR in "${ERRORS[@]}"; do
    echo "  - $ERR"
  done
  exit 1
fi

echo "OK"
