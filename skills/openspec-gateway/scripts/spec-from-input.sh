#!/usr/bin/env bash
set -euo pipefail

"$(dirname "$0")/ensure-env.sh"

title=""
description=""
acceptance_criteria=""
risk_tier=""
version="0.1.0"
output=""
force="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title) title="$2"; shift 2 ;;
    --description) description="$2"; shift 2 ;;
    --acceptance-criteria) acceptance_criteria="$2"; shift 2 ;;
    --risk-tier) risk_tier="$2"; shift 2 ;;
    --version) version="$2"; shift 2 ;;
    --output) output="$2"; shift 2 ;;
    --force-overwrite) force="true"; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$title" || -z "$description" ]]; then
  echo "BLOCKER:" >&2
  echo "code: MISSING_HANDOFF" >&2
  echo "required_input:" >&2
  [[ -z "$title" ]] && echo "- title" >&2
  [[ -z "$description" ]] && echo "- description" >&2
  echo "next_question: Provide the missing direct-input fields and retry." >&2
  exit 1
fi

if [[ -z "$risk_tier" ]]; then
  echo "BLOCKER:" >&2
  echo "code: RISK_TIER_REQUIRED" >&2
  echo "required_input:" >&2
  echo "- risk tier" >&2
  echo "next_question: Choose Low, Medium, High, or Critical before generating the spec." >&2
  exit 1
fi

if [[ -n "$output" && -f "$output" && "$force" != "true" ]]; then
  echo "BLOCKER:" >&2
  echo "code: OVERWRITE_APPROVAL_REQUIRED" >&2
  echo "required_input:" >&2
  echo "- explicit overwrite approval" >&2
  echo "next_question: Confirm overwrite approval and rerun with --force-overwrite." >&2
  exit 1
fi

spec="$(cat <<EOF
# ${title}

Version: ${version}
Risk Tier: ${risk_tier}

## Overview

${description}

## Scope

- In scope: <fill from normalized input>
- Out of scope: <fill from normalized input>

## Assumptions

- <assumption>

## Functional Requirements

- FR-1: ${title}

## Non-Functional Requirements

- NFR-1: <constraint>

## Acceptance Criteria

- AC-1: ${acceptance_criteria:-<missing acceptance criteria>}

## Open Questions

- <open question>
EOF
)"

if [[ -n "$output" ]]; then
  mkdir -p "$(dirname "$output")"
  printf '%s\n' "$spec" > "$output"
else
  printf '%s\n' "$spec"
fi
