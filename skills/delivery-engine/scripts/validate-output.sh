#!/usr/bin/env bash
# validate-output.sh
# Purpose: Validate Delivery Engine task-breakdown output against the required sections and task fields.
# Inputs: Contract text on stdin.
# Outputs: "OK" on stdout when valid; validation errors on stdout when invalid.
# Side effects: None.
set -euo pipefail

INPUT="$(cat)"
ERRORS=()

# Required top-level sections
for SECTION in "^tasks:" "^dependencies:" "^risks:" "^critical_path:" "^unknowns:" "^validation:"; do
  if ! printf '%s\n' "$INPUT" | grep -qE "$SECTION"; then
    ERRORS+=("missing section: ${SECTION//^/}")
  fi
done

# Every task must have a done_when condition
task_count="$(printf '%s\n' "$INPUT" | grep -cE '^- id: T-[0-9]+' || true)"
done_when_count="$(printf '%s\n' "$INPUT" | grep -cE '^\s+done_when:' || true)"
if [[ "$task_count" -gt 0 && "$done_when_count" -lt "$task_count" ]]; then
  ERRORS+=("every task must have a done_when condition ($done_when_count found for $task_count tasks)")
fi

# Every task must have an estimate or be a spike with a timebox
estimate_count="$(printf '%s\n' "$INPUT" | grep -cE '^\s+estimate: [SML]' || true)"
timebox_count="$(printf '%s\n' "$INPUT" | grep -cE '^\s+timebox:' || true)"
if [[ "$task_count" -gt 0 && $(( estimate_count + timebox_count )) -lt "$task_count" ]]; then
  ERRORS+=("every task must have an estimate (S/M/L) or a timebox for spikes")
fi

if [ ${#ERRORS[@]} -gt 0 ]; then
  echo "INVALID output:"
  for ERR in "${ERRORS[@]}"; do
    echo "  - $ERR"
  done
  exit 1
fi

echo "OK"
