#!/usr/bin/env bash
set -euo pipefail

INPUT="$(cat)"
ERRORS=()

for SECTION in "^spec:" "^quality_gates:" "^open_questions:"; do
  if ! printf '%s\n' "$INPUT" | grep -qE "$SECTION"; then
    ERRORS+=("missing section: ${SECTION//^/}")
  fi
done

if ! printf '%s\n' "$INPUT" | grep -qE '^[[:space:]]+- IN:'; then
  ERRORS+=("missing IN scope entry")
fi

if ! printf '%s\n' "$INPUT" | grep -qE '^[[:space:]]+- OUT:'; then
  ERRORS+=("missing OUT scope entry")
fi

if printf '%s\n' "$INPUT" | grep -qiE '\b(should|might|as needed)\b'; then
  ERRORS+=('requirements must be testable; found vague language')
fi

if ! printf '%s\n' "$INPUT" | grep -qE 'AC-[0-9]+.*GIVEN .+ WHEN .+ THEN .+'; then
  ERRORS+=("acceptance criteria must use GIVEN/WHEN/THEN")
fi

if ! printf '%s\n' "$INPUT" | grep -qE 'owner: .+ — due: .+'; then
  ERRORS+=("open questions must include owner and due date")
fi

if [ ${#ERRORS[@]} -gt 0 ]; then
  echo "INVALID output:"
  for ERR in "${ERRORS[@]}"; do
    echo "  - $ERR"
  done
  exit 1
fi

echo "OK"
