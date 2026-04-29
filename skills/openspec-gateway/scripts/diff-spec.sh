#!/usr/bin/env bash
set -euo pipefail

current="${1:?current spec required}"
baseline="${2:-}"

if [[ -z "$baseline" || ! -f "$baseline" ]]; then
  jq -n '{available: false, semantic_change_detected: false, warnings: ["baseline unavailable"], summary: {added_fr: [], removed_fr: [], added_ac: [], removed_ac: [], modified: []}}'
  exit 0
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

grep -oE 'FR-[0-9]+' "$baseline" | sort -u > "$tmp_dir/baseline-fr.txt" || true
grep -oE 'FR-[0-9]+' "$current" | sort -u > "$tmp_dir/current-fr.txt" || true
grep -oE 'AC-[0-9]+' "$baseline" | sort -u > "$tmp_dir/baseline-ac.txt" || true
grep -oE 'AC-[0-9]+' "$current" | sort -u > "$tmp_dir/current-ac.txt" || true

added_fr="$(comm -13 "$tmp_dir/baseline-fr.txt" "$tmp_dir/current-fr.txt" | jq -R . | jq -s 'map(select(length > 0))')"
removed_fr="$(comm -23 "$tmp_dir/baseline-fr.txt" "$tmp_dir/current-fr.txt" | jq -R . | jq -s 'map(select(length > 0))')"
added_ac="$(comm -13 "$tmp_dir/baseline-ac.txt" "$tmp_dir/current-ac.txt" | jq -R . | jq -s 'map(select(length > 0))')"
removed_ac="$(comm -23 "$tmp_dir/baseline-ac.txt" "$tmp_dir/current-ac.txt" | jq -R . | jq -s 'map(select(length > 0))')"
semantic="false"
if ! diff -q "$baseline" "$current" >/dev/null 2>&1; then
  semantic="true"
fi

jq -n \
  --argjson added_fr "$added_fr" \
  --argjson removed_fr "$removed_fr" \
  --argjson added_ac "$added_ac" \
  --argjson removed_ac "$removed_ac" \
  --arg semantic "$semantic" \
  '{
    available: true,
    semantic_change_detected: ($semantic == "true"),
    warnings: [],
    summary: {
      added_fr: $added_fr,
      removed_fr: $removed_fr,
      added_ac: $added_ac,
      removed_ac: $removed_ac,
      modified: []
    }
  }'
