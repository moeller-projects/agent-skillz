#!/usr/bin/env bash
# validate-output.sh
# Purpose: Validate Test Engine output against the test-plan, coverage-gaps, cases, and risk contract.
# Inputs: Contract text on stdin.
# Outputs: "OK" on stdout when valid; validation errors on stdout when invalid.
# Side effects: None.
set -euo pipefail

INPUT="$(cat)"
ERRORS=()

for SECTION in "^test-plan:" "^coverage-gaps:" "^cases:" "^risk:"; do
  if ! printf '%s\n' "$INPUT" | grep -qE "$SECTION"; then
    ERRORS+=("missing section: ${SECTION//^/}")
  fi
done

if ! printf '%s\n' "$INPUT" | grep -qiE 'given .+ when .+ then .+'; then
  given_count="$(printf '%s\n' "$INPUT" | grep -cE '^[[:space:]]+given:' || true)"
  when_count="$(printf '%s\n' "$INPUT" | grep -cE '^[[:space:]]+when:' || true)"
  then_count="$(printf '%s\n' "$INPUT" | grep -cE '^[[:space:]]+then:' || true)"
  if [ "$given_count" -lt 1 ] || [ "$when_count" -lt 1 ] || [ "$then_count" -lt 1 ]; then
    ERRORS+=("test cases must use GIVEN/WHEN/THEN")
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
