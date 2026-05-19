#!/usr/bin/env bash
# validate-output.sh
# Purpose: Validate Repo Engine output against the repo-map, entrypoint, convention, hotspot, and artifact contract.
# Inputs: Contract text on stdin.
# Outputs: "OK" on stdout when valid; validation errors on stdout when invalid.
# Side effects: None.
set -euo pipefail

INPUT="$(cat)"
ERRORS=()

for SECTION in "^repo_map:" "^entrypoints:" "^conventions:" "^hotspots:" "^agent_artifacts:"; do
  if ! printf '%s\n' "$INPUT" | grep -qE "$SECTION"; then
    ERRORS+=("missing section: ${SECTION//^/}")
  fi
done

if ! printf '%s\n' "$INPUT" | grep -qE '^- .+ — .+'; then
  ERRORS+=("repo_map entries must include a one-line description")
fi

if ! printf '%s\n' "$INPUT" | grep -qE '^hotspots:'; then
  ERRORS+=("missing hotspots section")
elif ! printf '%s\n' "$INPUT" | grep -qE '^- .+ — .+'; then
  ERRORS+=("hotspots must include a concrete reason")
fi

if [ ${#ERRORS[@]} -gt 0 ]; then
  echo "INVALID output:"
  for ERR in "${ERRORS[@]}"; do
    echo "  - $ERR"
  done
  exit 1
fi

echo "OK"
