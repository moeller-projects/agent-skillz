#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
"$script_dir/ensure-env.sh"
. "$script_dir/validate-risk-tier.sh"

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
  echo "recovery: Regenerate the handoff with ado-gateway and ensure the handoff targets openspec-gateway." >&2
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

if ! validate_risk_tier "$risk_tier"; then
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
{
  printf '# %s\n\n' "$title"
  printf 'Version: %s\n' "$version"
  printf 'Risk Tier: %s\n\n' "$risk_tier"
  printf '## Overview\n\n%s\n\n' "$description"
  printf '## Scope\n\n'
  printf -- '- In scope: %s\n' "$title"
  printf '%s\n\n' '- Out of scope: follow-up work not described in the handoff'
  printf '## Assumptions\n\n'
  printf '%s\n\n' '- Source of truth is the normalized Azure DevOps handoff.'
  printf '## Functional Requirements\n\n'
  printf -- '- FR-1: <replace with the primary functional behavior required for "%s">\n\n' "$title"
  printf '## Non-Functional Requirements\n\n'
  printf '%s\n\n' '- NFR-1: Preserve traceability back to the normalized handoff.'
  printf '## Acceptance Criteria\n\n'
  printf -- '- AC-1: %s\n\n' "${acceptance_criteria:-<missing acceptance criteria>}"
  printf '## Review Context\n\n'
  printf '%s\n\n' "$comments_block"
  printf '## Open Questions\n\n'
  if [[ -z "$acceptance_criteria" ]]; then
    printf '%s\n' '- Acceptance criteria were missing from the handoff.'
  else
    printf '%s\n' '- None.'
  fi
} > "$output"

printf '%s\n' "$output"
