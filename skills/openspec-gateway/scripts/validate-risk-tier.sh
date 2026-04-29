#!/usr/bin/env bash
set -euo pipefail

validate_risk_tier() {
  local risk_tier="${1:-}"
  if [[ "$risk_tier" =~ ^(Low|Medium|High|Critical)$ ]]; then
    return 0
  fi

  echo "BLOCKER:" >&2
  echo "code: RISK_TIER_REQUIRED" >&2
  echo "required_input:" >&2
  echo "- risk tier (Low|Medium|High|Critical)" >&2
  echo "next_question: Choose one of Low, Medium, High, or Critical before generating the spec." >&2
  return 1
}
