#!/usr/bin/env bash
# resolve-ado-user.sh
# Resolves an Azure DevOps user identity by email for work-item mention markup.
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

tmp_body="$(mktemp)"
tmp_matches="$(mktemp)"
trap 'rm -f "$tmp_body" "$tmp_matches"' EXIT

email_lower="$(tr '[:upper:]' '[:lower:]' <<<"$email")"
email_encoded="$(jq -rn --arg value "$email_lower" '$value|@uri')"
url="https://vssps.dev.azure.com/$organization/_apis/identities?searchFilter=General&filterValue=$email_encoded&queryMembership=None&api-version=7.1"

if ! curl -fsS \
  --retry 5 \
  --retry-delay 2 \
  --retry-max-time 60 \
  --retry-all-errors \
  -u ":${AZURE_DEVOPS_PAT}" \
  -H "Accept: application/json" \
  "$url" > "$tmp_body"; then
  echo "ERROR:" >&2
  echo "code: FETCH_FAILED" >&2
  echo "stage: fetch" >&2
  echo "message: Failed to query Azure DevOps identities for $organization after bounded retries." >&2
  echo "recovery: Check AZURE_DEVOPS_PAT permissions, organization name, and network connectivity." >&2
  exit 1
fi

jq -c --arg target "$email_lower" '
  [(.value // [])[] | select(
    ((.properties.Mail."$value" // .properties.Account."$value" // .properties.SignInAddress."$value" // "" | ascii_downcase) == $target)
    or ((.providerDisplayName // "" | ascii_downcase) == $target)
    or ((.customDisplayName // "" | ascii_downcase) == $target)
    or ((.uniqueName // "" | ascii_downcase) == $target)
  )]
' "$tmp_body" > "$tmp_matches"

match_count="$(jq 'length' "$tmp_matches")"
if [[ "$match_count" == "0" ]]; then
  echo "ERROR:" >&2
  echo "code: FETCH_FAILED" >&2
  echo "stage: fetch" >&2
  echo "message: No Azure DevOps identity was found for email $email in organization $organization." >&2
  echo "recovery: Verify the email is in this Azure DevOps organization and retry." >&2
  exit 1
fi
if [[ "$match_count" != "1" ]]; then
  echo "ERROR:" >&2
  echo "code: FETCH_FAILED" >&2
  echo "stage: fetch" >&2
  echo "message: Multiple Azure DevOps identities matched email $email in organization $organization." >&2
  echo "recovery: Resolve the identity ambiguity in Azure DevOps, then retry with a unique email." >&2
  exit 1
fi

resolved_user="$(jq '.[0]' "$tmp_matches")"
mention_id="$(jq -r '.id // .originId // ""' <<<"$resolved_user")"
if [[ -z "$mention_id" ]]; then
  echo "ERROR:" >&2
  echo "code: PARSE_FAILED" >&2
  echo "stage: parse" >&2
  echo "message: Azure DevOps identity response did not include id or originId for $email." >&2
  echo "recovery: Check Azure DevOps identity data and retry." >&2
  exit 1
fi

display_name="$(jq -r '.providerDisplayName // .customDisplayName // .displayName // ""' <<<"$resolved_user")"
[[ -z "$display_name" ]] && display_name="$email"
mention_markup="$("$script_dir/format-work-item-mention.sh" --mention-id "$mention_id" --display-name "$display_name")"

jq -n \
  --arg organization "$organization" \
  --arg email "$email" \
  --arg mention_id "$mention_id" \
  --arg descriptor "$(jq -r '.descriptor // ""' <<<"$resolved_user")" \
  --arg identity_id "$(jq -r '.id // ""' <<<"$resolved_user")" \
  --arg origin_id "$(jq -r '.originId // ""' <<<"$resolved_user")" \
  --arg display_name "$display_name" \
  --arg principal_name "$(jq -r '.uniqueName // .principalName // ""' <<<"$resolved_user")" \
  --arg mention_markup "$mention_markup" \
  '{organization:$organization,email:$email,mention_id:$mention_id,descriptor:$descriptor,identity_id:$identity_id,origin_id:$origin_id,display_name:$display_name,principal_name:$principal_name,mention_markup:$mention_markup}'
