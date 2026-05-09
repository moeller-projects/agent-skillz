#!/usr/bin/env bash
set -euo pipefail

INPUT="$(cat)"
ERRORS=()

for SECTION in "^test-plan:" "^coverage-gaps:" "^cases:" "^risk:"; do
  if ! printf '%s\n' "$INPUT" | grep -qE "$SECTION"; then
    ERRORS+=("missing section: ${SECTION//^/}")
  fi
done

if ! printf '%s\n' "$INPUT" | grep -qiE 'given .+ when .+ then .+'; then
  ERRORS+=("test cases must use GIVEN/WHEN/THEN")
fi

if [ ${#ERRORS[@]} -gt 0 ]; then
  echo "INVALID output:"
  for ERR in "${ERRORS[@]}"; do
    echo "  - $ERR"
  done
  exit 1
fi

echo "OK"
