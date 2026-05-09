#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
"$script_dir/ensure-env.sh"
. "$script_dir/validate-risk-tier.sh"

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
  echo "code: MISSING_INPUT" >&2
  echo "required_input:" >&2
  [[ -z "$title" ]] && echo "- title" >&2
  [[ -z "$description" ]] && echo "- description" >&2
  echo "next_question: Provide the missing direct-input fields and retry." >&2
  exit 1
fi

if ! validate_risk_tier "$risk_tier"; then
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

emit_spec() {
  printf '# %s\n\n' "$title"
  printf 'Version: %s\n' "$version"
  printf 'Risk Tier: %s\n\n' "$risk_tier"
  printf '## Overview\n\n%s\n\n' "$description"
  printf '## Scope\n\n'
  printf '%s\n' '- In scope: <fill from normalized input>'
  printf '%s\n\n' '- Out of scope: <fill from normalized input>'
  printf '## Assumptions\n\n'
  printf '%s\n\n' '- <assumption>'
  printf '## Functional Requirements\n\n'
  printf -- '- FR-1: <replace with the primary functional behavior required for "%s">\n\n' "$title"
  printf '## Non-Functional Requirements\n\n'
  printf '%s\n\n' '- NFR-1: <constraint>'
  printf '## Acceptance Criteria\n\n'
  printf -- '- AC-1: %s\n\n' "${acceptance_criteria:-<missing acceptance criteria>}"
  printf '## Review Context\n\n'
  printf '%s\n\n' '- None.'
  printf '## Open Questions\n\n'
  printf '%s\n' '- <open question>'
}

if [[ -n "$output" ]]; then
  mkdir -p "$(dirname "$output")"
  emit_spec > "$output"
else
  emit_spec
fi
