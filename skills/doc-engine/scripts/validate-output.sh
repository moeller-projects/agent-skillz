#!/usr/bin/env bash
set -euo pipefail

INPUT="$(cat)"
ERRORS=()

if printf '%s\n' "$INPUT" | grep -qE '^decision:'; then
  for FIELD in '^  context:' '^  decision:' '^  reasoning:' '^  tradeoffs:' '^  reuse_scope:'; do
    if ! printf '%s\n' "$INPUT" | grep -qE "$FIELD"; then
      ERRORS+=("missing decision field: ${FIELD#^  }")
    fi
  done
else
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

  STRUCTURE_LINES=$(printf '%s\n' "$INPUT" | grep -E '^\s+[0-9]+\.' || true)
  if [ -n "$STRUCTURE_LINES" ]; then
    while IFS= read -r line; do
      if ! printf '%s\n' "$line" | grep -qE '\[(tutorial|how-to|reference|explanation)\]'; then
        ERRORS+=("structure entry missing valid mode tag [tutorial|how-to|reference|explanation]: $line")
      fi
    done <<< "$STRUCTURE_LINES"
  fi

  if printf '%s\n' "$INPUT" | grep -qE '^--- '; then
    if ! printf '%s\n' "$INPUT" | grep -qE '^reason:'; then
      ERRORS+=("diff output must include reason:")
    fi
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
