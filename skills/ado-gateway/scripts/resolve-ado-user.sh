#!/usr/bin/env bash
# resolve-ado-user.sh
# Resolves an Azure DevOps user by email via the Azure DevOps Graph API.
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
"$script_dir/ensure-env.sh" --require-pat

organization="${ADO_ORGANIZATION:-}"
email=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --organization) organization="$2"; shift 2 ;;
    --email) email="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

missing=()
[[ -z "$organization" ]] && missing+=(organization)
[[ -z "$email" ]] && missing+=(email)
if [[ ${#missing[@]} -gt 0 ]]; then
  echo "BLOCKER:" >&2
  echo "code: MISSING_INPUT" >&2
  echo "required_input:" >&2
  for item in "${missing[@]}"; do echo "- $item" >&2; done
  echo "next_question: Provide organization and email before resolving an Azure DevOps user." >&2
  exit 1
fi

if [[ "$email" != *"@"* ]]; then
  echo "ERROR:" >&2
  echo "code: PARSE_FAILED" >&2
  echo "stage: parse" >&2
  echo "message: --email must be a valid email address." >&2
  echo "recovery: Provide an email address such as user@example.com." >&2
  exit 1
fi

tmp_matches="$(mktemp)"
trap 'rm -f "$tmp_matches"' EXIT
printf '[]' > "$tmp_matches"

continuation_token=""
while :; do
  url="https://vssps.dev.azure.com/$organization/_apis/graph/users?api-version=7.1-preview.1"
  if [[ -n "$continuation_token" ]]; then
    continuation_encoded="$(jq -rn --arg value "$continuation_token" '$value|@uri')"
    url="${url}&continuationToken=${continuation_encoded}"
  fi

  tmp_headers="$(mktemp)"
  tmp_body="$(mktemp)"
  trap 'rm -f "$tmp_matches" "$tmp_headers" "$tmp_body"' EXIT

  if ! curl -fsS \
    --retry 5 \
    --retry-delay 2 \
    --retry-max-time 60 \
    --retry-all-errors \
    -u ":${AZURE_DEVOPS_PAT}" \
    -H "Accept: application/json" \
    -D "$tmp_headers" \
    "$url" > "$tmp_body"; then
    echo "ERROR:" >&2
    echo "code: FETCH_FAILED" >&2
    echo "stage: fetch" >&2
    echo "message: Failed to query Azure DevOps Graph users for $organization after bounded retries." >&2
    echo "recovery: Check AZURE_DEVOPS_PAT permissions, organization name, and network connectivity." >&2
    exit 1
  fi

  page_matches="$(
    jq -c --arg target "$(tr '[:upper:]' '[:lower:]' <<<"$email")" '
      [(.value // [])[] | select(((.mailAddress // "" | ascii_downcase) == $target) or ((.principalName // "" | ascii_downcase) == $target))]
    ' "$tmp_body"
  )"
  jq -c --argjson current "$(cat "$tmp_matches")" --argjson page "$page_matches" '$current + $page' <<<"{}" > "$tmp_matches"

  continuation_token="$(
    awk 'BEGIN{IGNORECASE=1} /^x-ms-continuationtoken:/ {token=$2} END {gsub(/\r/, "", token); print token}' "$tmp_headers"
  )"
  rm -f "$tmp_headers" "$tmp_body"
  trap 'rm -f "$tmp_matches"' EXIT

  if [[ -z "$continuation_token" ]]; then
    break
  fi
done

match_count="$(jq 'length' "$tmp_matches")"
if [[ "$match_count" == "0" ]]; then
  echo "ERROR:" >&2
  echo "code: FETCH_FAILED" >&2
  echo "stage: fetch" >&2
  echo "message: No Azure DevOps Graph user was found for email $email in organization $organization." >&2
  echo "recovery: Verify the email is in this Azure DevOps organization and retry." >&2
  exit 1
fi
if [[ "$match_count" != "1" ]]; then
  echo "ERROR:" >&2
  echo "code: FETCH_FAILED" >&2
  echo "stage: fetch" >&2
  echo "message: Multiple Azure DevOps Graph users matched email $email in organization $organization." >&2
  echo "recovery: Resolve the identity ambiguity in Azure DevOps, then retry with a unique email." >&2
  exit 1
fi

resolved_user="$(jq '.[0]' "$tmp_matches")"
descriptor="$(jq -r '.descriptor // ""' <<<"$resolved_user")"
if [[ -z "$descriptor" ]]; then
  echo "ERROR:" >&2
  echo "code: PARSE_FAILED" >&2
  echo "stage: parse" >&2
  echo "message: Azure DevOps Graph response did not include descriptor for $email." >&2
  echo "recovery: Check Azure DevOps identity data and retry." >&2
  exit 1
fi

display_name="$(jq -r '.displayName // ""' <<<"$resolved_user")"
[[ -z "$display_name" ]] && display_name="$email"
mention_markup="$("$script_dir/format-work-item-mention.sh" --mention-id "$descriptor" --display-name "$display_name")"

jq -n \
  --arg organization "$organization" \
  --arg email "$email" \
  --arg descriptor "$descriptor" \
  --arg origin_id "$(jq -r '.originId // ""' <<<"$resolved_user")" \
  --arg display_name "$display_name" \
  --arg principal_name "$(jq -r '.principalName // ""' <<<"$resolved_user")" \
  --arg mention_markup "$mention_markup" \
  '{organization:$organization,email:$email,descriptor:$descriptor,origin_id:$origin_id,display_name:$display_name,principal_name:$principal_name,mention_markup:$mention_markup}'
