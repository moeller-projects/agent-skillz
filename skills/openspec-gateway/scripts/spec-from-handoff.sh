#!/usr/bin/env bash
set -euo pipefail

"$(dirname "$0")/ensure-env.sh"

handoff_file="${1:-}"
output="${2:-}"
risk_tier="${RISK_TIER:-}"
version="${VERSION:-0.1.0}"
force="${FORCE_OVERWRITE:-false}"

if [[ -z "$handoff_file" || ! -f "$handoff_file" ]]; then
  echo "BLOCKER:" >&2
  echo "code: MISSING_HANDOFF" >&2
  echo "required_input:" >&2
  echo "- handoff JSON file" >&2
  echo "next_question: Provide a valid handoff JSON file and retry." >&2
  exit 1
fi

producer="$(jq -r '.producer // ""' "$handoff_file")"
consumer="$(jq -r '.consumer // ""' "$handoff_file")"
title="$(jq -r '.work_item.title // ""' "$handoff_file")"
description="$(jq -r '.work_item.description // ""' "$handoff_file")"
acceptance_criteria="$(jq -r '.work_item.acceptance_criteria // ""' "$handoff_file")"
comments="$(jq -r '.pr_comments[]?.content // empty' "$handoff_file")"

if [[ "$producer" != "ado-gateway" || "$consumer" != "openspec-gateway" ]]; then
  echo "ERROR:" >&2
  echo "code: INGEST_FAILED" >&2
  echo "stage: ingest" >&2
  echo "message: Invalid handoff producer or consumer." >&2
  echo "recovery: Regenerate the handoff with ado-gateway and retry." >&2
  exit 1
fi

if [[ -z "$title" || -z "$description" ]]; then
  echo "BLOCKER:" >&2
  echo "code: MISSING_HANDOFF" >&2
  echo "required_input:" >&2
  [[ -z "$title" ]] && echo "- work_item.title" >&2
  [[ -z "$description" ]] && echo "- work_item.description" >&2
  echo "next_question: Regenerate the handoff with title and description populated." >&2
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

spec_name="$(dirname "$0")/resolve-spec-name.sh"
slug="$($spec_name "$title")"
if [[ -z "$output" ]]; then
  output="${slug}.md"
fi

if [[ -f "$output" && "$force" != "true" ]]; then
  echo "BLOCKER:" >&2
  echo "code: OVERWRITE_APPROVAL_REQUIRED" >&2
  echo "required_input:" >&2
  echo "- explicit overwrite approval" >&2
  echo "next_question: Confirm overwrite approval and set FORCE_OVERWRITE=true before retrying." >&2
  exit 1
fi

comments_block="- None"
if [[ -n "$comments" ]]; then
  comments_block="$(printf '%s\n' "$comments" | sed 's/^/- /')"
fi

mkdir -p "$(dirname "$output")"
cat > "$output" <<EOF
# ${title}

Version: ${version}
Risk Tier: ${risk_tier}

## Overview

${description}

## Scope

- In scope: ${title}
- Out of scope: follow-up work not described in the handoff

## Assumptions

- Source of truth is the normalized Azure DevOps handoff.

## Functional Requirements

- FR-1: ${title}

## Non-Functional Requirements

- NFR-1: Preserve traceability back to the normalized handoff.

## Acceptance Criteria

- AC-1: ${acceptance_criteria:-<missing acceptance criteria>}

## Review Context

${comments_block}

## Open Questions

$(if [[ -z "$acceptance_criteria" ]]; then echo '- Acceptance criteria were missing from the handoff.'; else echo '- None.'; fi)
EOF

printf '%s\n' "$output"
