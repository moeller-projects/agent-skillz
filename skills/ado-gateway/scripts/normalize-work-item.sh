#!/usr/bin/env bash
set -euo pipefail

tmp_json="$(mktemp)"
trap 'rm -f "$tmp_json"' EXIT
cat > "$tmp_json"

html_to_text() {
  perl -0pe 's#<br\s*/?>#\n#gsi; s#</p>#\n#gsi; s#<li># - #gsi; s#<[^>]+>##g; s/&nbsp;/ /g; s/&amp;/&/g; s/&lt;/</g; s/&gt;/>/g;'
}

redact_tokens() {
  perl -0pe 's/(Bearer\s+)[A-Za-z0-9._-]+/${1}[REDACTED]/g; s/[A-Za-z0-9]{20,}\.[A-Za-z0-9._-]{10,}/[REDACTED]/g;'
}

work_item_type="$(jq -r '.fields."System.WorkItemType" // ""' "$tmp_json")"

description="$(jq -r '.fields."System.Description" // ""' "$tmp_json" | html_to_text | redact_tokens)"
acceptance="$(jq -r '.fields."Microsoft.VSTS.Common.AcceptanceCriteria" // .fields."Custom.AcceptanceCriteria" // ""' "$tmp_json" | html_to_text | redact_tokens)"
repro=""
system_info=""
if [[ "$work_item_type" == "Bug" ]]; then
  repro="$(jq -r '.fields."Microsoft.VSTS.TCM.ReproSteps" // .fields."Custom.ReproSteps" // ""' "$tmp_json" | html_to_text | redact_tokens)"
  system_info="$(jq -r '.fields."Microsoft.VSTS.TCM.SystemInfo" // .fields."Custom.SystemInfo" // ""' "$tmp_json" | html_to_text | redact_tokens)"
fi

jq -n \
  --arg id "$(jq -r '.id // empty' "$tmp_json")" \
  --arg type "$work_item_type" \
  --arg title "$(jq -r '.fields."System.Title" // ""' "$tmp_json" | redact_tokens)" \
  --arg description "$description" \
  --arg acceptance_criteria "$acceptance" \
  --arg repro_steps "$repro" \
  --arg system_info "$system_info" \
  --arg tags "$(jq -r '.fields."System.Tags" // ""' "$tmp_json")" \
  --arg state "$(jq -r '.fields."System.State" // ""' "$tmp_json")" \
  '{
    id: $id,
    type: $type,
    title: $title,
    description: $description,
    acceptance_criteria: $acceptance_criteria,
    repro_steps: $repro_steps,
    system_info: $system_info,
    tags: $tags,
    state: $state
  }'
