#!/usr/bin/env bash
set -euo pipefail

spec_file="${1:?spec file required}"
fr_count="$(grep -cE '^[[:space:]]*- FR-[0-9]+' "$spec_file" || true)"
ac_count="$(grep -cE '^[[:space:]]*- AC-[0-9]+' "$spec_file" || true)"
has_nfr="$(grep -c '^## Non-Functional Requirements' "$spec_file" || true)"
has_questions="$(grep -c '^## Open Questions' "$spec_file" || true)"

coverage=0
testability=0
constraints=0
clarity=20
readiness=0
warnings=()
remediation_hints=()

if [[ "$fr_count" -gt 0 ]]; then coverage=25; else warnings+=("missing functional requirements"); remediation_hints+=("Add at least one FR-* item in the Functional Requirements section."); fi
if [[ "$ac_count" -gt 0 ]]; then testability=20; else warnings+=("missing acceptance criteria"); remediation_hints+=("Add at least one AC-* item in the Acceptance Criteria section."); fi
if [[ "$has_nfr" -gt 0 ]]; then constraints=20; else warnings+=("missing non-functional requirements section"); remediation_hints+=("Add the Non-Functional Requirements section with at least one NFR-* item."); fi
if [[ "$has_questions" -gt 0 ]]; then readiness=15; else warnings+=("missing open questions section"); remediation_hints+=("Add the Open Questions section even when the current answer is 'None.'"); fi
if grep -qiE '\b(should|might|etc\.)\b' "$spec_file"; then
  clarity=10
  warnings+=("vague language detected")
  remediation_hints+=("Replace vague words like 'should', 'might', or 'etc.' with testable language.")
fi

score=$((coverage + testability + constraints + clarity + readiness))
passing="false"
if [[ "$score" -ge 80 ]]; then
  passing="true"
fi

warnings_json="$(printf '%s\n' "${warnings[@]:-}" | jq -R . | jq -s 'map(select(length > 0))')"
remediation_json="$(printf '%s\n' "${remediation_hints[@]:-}" | jq -R . | jq -s 'map(select(length > 0))')"

jq -n \
  --argjson score "$score" \
  --argjson coverage "$coverage" \
  --argjson testability "$testability" \
  --argjson constraints "$constraints" \
  --argjson clarity "$clarity" \
  --argjson readiness "$readiness" \
  --arg passing "$passing" \
  --argjson warnings "$warnings_json" \
  --argjson remediation_hints "$remediation_json" \
  '{
    score: $score,
    passing: ($passing == "true"),
    breakdown: {
      coverage: $coverage,
      testability: $testability,
      constraints: $constraints,
      clarity: $clarity,
      readiness: $readiness
    },
    warnings: $warnings,
    remediation_hints: $remediation_hints
  }'

if [[ "$passing" != "true" ]]; then
  exit 1
fi
