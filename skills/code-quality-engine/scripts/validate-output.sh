#!/usr/bin/env bash
# validate-output.sh — Code Quality Engine
# Usage: echo "<output>" | bash validate-output.sh
# Exit 0 = valid, Exit 1 = invalid
set -euo pipefail

INPUT=$(cat)
ERRORS=()

# Check findings section exists
if ! echo "$INPUT" | grep -qE "^findings:"; then
  ERRORS+=("missing 'findings:' section")
fi

# Check patch-plan section exists
if ! echo "$INPUT" | grep -qE "^patch-plan:"; then
  ERRORS+=("missing 'patch-plan:' section")
fi

# Check risk section exists
if ! echo "$INPUT" | grep -qE "^risk:"; then
  ERRORS+=("missing 'risk:' section")
fi

# Check severity labels are valid
INVALID_SEV=$(echo "$INPUT" | grep -oE '\[(critical|high|medium|low|CRITICAL|HIGH|MEDIUM|LOW)\]' | grep -vE '\[(critical|high|medium|low)\]' || true)
if [ -n "$INVALID_SEV" ]; then
  ERRORS+=("invalid severity label: $INVALID_SEV (must be lowercase)")
fi

if [ ${#ERRORS[@]} -gt 0 ]; then
  echo "INVALID output:"
  for ERR in "${ERRORS[@]}"; do
    echo "  - $ERR"
  done
  exit 1
fi

echo "OK"
