#!/usr/bin/env bash
# validate-output.sh
# Purpose: Validate Thinking Engine output against the problem, assumptions, options, recommendation, and next contract.
# Inputs: Contract text on stdin.
# Outputs: "OK" on stdout when valid; validation errors on stdout when invalid.
# Side effects: None.
set -euo pipefail

INPUT="$(cat)"
ERRORS=()

for SECTION in "^problem:" "^assumptions:" "^options:" "^recommendation:" "^next:"; do
  if ! printf '%s\n' "$INPUT" | grep -qE "$SECTION"; then
    ERRORS+=("missing section: ${SECTION//^/}")
  fi
done

option_count="$(printf '%s\n' "$INPUT" | awk '/^options:/{found=1;next} found && /^[a-z][a-zA-Z_-]*:/{found=0} found{print}' | grep -cE '^[0-9]+\.' || true)"
if [ "$option_count" -lt 1 ]; then
  ERRORS+=("options must include at least one numbered option")
fi

if [ ${#ERRORS[@]} -gt 0 ]; then
  echo "INVALID output:" >&2
  for ERR in "${ERRORS[@]}"; do
    echo "  - $ERR" >&2
  done
  exit 1
fi

echo "OK"
