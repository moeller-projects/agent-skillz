#!/usr/bin/env bash
# validate-output.sh
# Purpose: Validate Doc Engine outputs for doc-plan, diff-oriented, and decision-record contracts.
# Inputs: Contract text on stdin.
# Outputs: "OK" on stdout when valid; validation errors on stdout when invalid.
# Side effects: None.
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

  if printf '%s\n' "$INPUT" | grep -qE '^- format:'; then
    if ! printf '%s\n' "$INPUT" | grep -qE 'type: (markdown|html)'; then
      ERRORS+=("missing format type: markdown|html")
    fi
    if ! printf '%s\n' "$INPUT" | grep -qE '^\s*- artifact:'; then
      ERRORS+=("missing artifact field")
    fi
    if printf '%s\n' "$INPUT" | grep -qE 'type: html'; then
      if printf '%s\n' "$INPUT" | grep -qE '<html>|<head>|<style>|<body>'; then
        for TOKEN in '<html>' '<head>' '<style>' '<body>' 'print'; do
          if ! printf '%s\n' "$INPUT" | grep -qF "$TOKEN"; then
            ERRORS+=("missing html validation token: $TOKEN")
          fi
        done
        if printf '%s\n' "$INPUT" | grep -qE '<link[^>]+stylesheet|<script[^>]+src='; then
          ERRORS+=("html output must avoid external stylesheet/script dependencies")
        fi
      fi
    fi
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
