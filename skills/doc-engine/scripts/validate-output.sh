#!/usr/bin/env bash
set -euo pipefail

INPUT="$(cat)"
ERRORS=()

for SECTION in "^doc:" "^changes:" "^gaps:"; do
  if ! printf '%s\n' "$INPUT" | grep -qE "$SECTION"; then
    ERRORS+=("missing section: ${SECTION//^/}")
  fi
done

if ! printf '%s\n' "$INPUT" | grep -qE "^- purpose:"; then
  ERRORS+=("missing doc purpose")
fi

if ! printf '%s\n' "$INPUT" | grep -qE "^- audience:"; then
  ERRORS+=("missing doc audience")
fi

if ! printf '%s\n' "$INPUT" | grep -qE "^- structure:"; then
  ERRORS+=("missing doc structure")
fi

if printf '%s\n' "$INPUT" | grep -qE '^--- '; then
  if ! printf '%s\n' "$INPUT" | grep -qE '^reason:'; then
    ERRORS+=("diff output must include reason:")
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
