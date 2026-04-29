#!/usr/bin/env bash
set -euo pipefail

spec_file="${1:?spec file required}"
diff_file="${2:-}"
baseline_file="${3:-}"
header="$(head -n 40 "$spec_file")"
version="$(grep -m1 '^Version:' "$spec_file" | sed 's/^Version:[[:space:]]*//' || true)"
risk_tier="$(grep -m1 '^Risk Tier:' "$spec_file" | sed 's/^Risk Tier:[[:space:]]*//' || true)"

errors=()
if [[ -z "$version" ]]; then errors+=("missing Version line"); fi
if [[ -z "$risk_tier" ]]; then errors+=("missing Risk Tier line"); fi
if [[ -n "$version" ]] && ! grep -q '^Version:' <<<"$header"; then errors+=("Version line must be within first 40 lines"); fi
if [[ -n "$risk_tier" ]] && ! grep -q '^Risk Tier:' <<<"$header"; then errors+=("Risk Tier line must be within first 40 lines"); fi

version_changed="true"
if [[ -n "$baseline_file" && -f "$baseline_file" ]]; then
  baseline_version="$(grep -m1 '^Version:' "$baseline_file" | sed 's/^Version:[[:space:]]*//' || true)"
  if [[ -n "$baseline_version" && "$baseline_version" == "$version" ]]; then
    version_changed="false"
  fi
fi

if [[ -n "$diff_file" && -f "$diff_file" ]]; then
  semantic="$(jq -r '.semantic_change_detected // false' "$diff_file")"
  change_count="$(jq '[.summary.added_fr[], .summary.removed_fr[], .summary.added_ac[], .summary.removed_ac[]] | length' "$diff_file")"
  if { [[ "$semantic" == "true" ]] || [[ "$change_count" -gt 0 ]]; } && [[ "$version_changed" != "true" ]]; then
    errors+=("version must change when requirements or acceptance criteria change")
  fi
fi

jq -n \
  --arg version "$version" \
  --arg risk_tier "$risk_tier" \
  --argjson errors "$(printf '%s\n' "${errors[@]:-}" | jq -R . | jq -s 'map(select(length > 0))')" \
  '{pass: ($errors | length == 0), version: $version, risk_tier: $risk_tier, errors: $errors}'

if [[ ${#errors[@]} -gt 0 ]]; then
  exit 1
fi
