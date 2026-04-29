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

if [[ "$fr_count" -gt 0 ]]; then coverage=25; else warnings+=("missing functional requirements"); fi
if [[ "$ac_count" -gt 0 ]]; then testability=20; else warnings+=("missing acceptance criteria"); fi
if [[ "$has_nfr" -gt 0 ]]; then constraints=20; else warnings+=("missing non-functional requirements section"); fi
if [[ "$has_questions" -gt 0 ]]; then readiness=15; else warnings+=("missing open questions section"); fi
if grep -qiE '\b(should|might|etc\.)\b' "$spec_file"; then
  clarity=10
  warnings+=("vague language detected")
fi

score=$((coverage + testability + constraints + clarity + readiness))
passing="false"
if [[ "$score" -ge 80 ]]; then
  passing="true"
fi

warnings_json="$(printf '%s\n' "${warnings[@]:-}" | jq -R . | jq -s 'map(select(length > 0))')"

jq -n \
  --argjson score "$score" \
  --argjson coverage "$coverage" \
  --argjson testability "$testability" \
  --argjson constraints "$constraints" \
  --argjson clarity "$clarity" \
  --argjson readiness "$readiness" \
  --arg passing "$passing" \
  --argjson warnings "$warnings_json" \
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
    remediation_hints: $warnings
  }'

if [[ "$passing" != "true" ]]; then
  exit 1
fi
