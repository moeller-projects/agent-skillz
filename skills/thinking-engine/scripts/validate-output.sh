#!/usr/bin/env bash
set -euo pipefail

INPUT="$(cat)"
ERRORS=()

for SECTION in "^problem:" "^assumptions:" "^options:" "^recommendation:" "^next:"; do
  if ! printf '%s\n' "$INPUT" | grep -qE "$SECTION"; then
    ERRORS+=("missing section: ${SECTION//^/}")
  fi
done

option_count="$(printf '%s\n' "$INPUT" | grep -cE '^[0-9]+\. ' || true)"
if [ "$option_count" -lt 1 ]; then
  ERRORS+=("options must include at least one numbered option")
fi

if [ ${#ERRORS[@]} -gt 0 ]; then
  echo "INVALID output:"
  for ERR in "${ERRORS[@]}"; do
    echo "  - $ERR"
  done
  exit 1
fi

echo "OK"
