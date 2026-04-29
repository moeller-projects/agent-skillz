#!/usr/bin/env bash
set -euo pipefail

spec_file="${1:?spec file required}"
validation_file="${2:?validation json required}"
score_file="${3:?score json required}"
diff_file="${4:?diff json required}"
version_file="${5:?version json required}"

spec_name="$(basename "$spec_file")"
version="$(jq -r '.version // ""' "$version_file")"
risk_tier="$(jq -r '.risk_tier // ""' "$version_file")"
validation="$(jq -r '.validation // "fail"' "$validation_file")"
version_pass="$(jq -r '.pass // false' "$version_file")"

jq -n \
  --arg spec_name "$spec_name" \
  --arg spec_file "$spec_file" \
  --arg version "$version" \
  --arg risk_tier "$risk_tier" \
  --arg validation "$validation" \
  --arg version_pass "$version_pass" \
  --argjson gates "$(jq -c '.gates' "$validation_file")" \
  --argjson quality "$(cat "$score_file")" \
  --argjson diff "$(cat "$diff_file")" \
  '{
    spec_name: $spec_name,
    spec_file: $spec_file,
    risk_tier: $risk_tier,
    version: $version,
    validation: (if $validation == "pass" and $version_pass == "true" then "pass" else "fail" end),
    gates: $gates,
    quality: $quality,
    diff: $diff,
    signoff: {
      tech_lead: "",
      qa: "",
      timestamp: ""
    },
    downstream_recommendations: (
      if $risk_tier == "High" or $risk_tier == "Critical" then ["Require architecture or security review"] else [] end
    )
  }'
