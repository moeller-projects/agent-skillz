#!/usr/bin/env bash
# parse-pr-url.sh
# Purpose: Parse an Azure DevOps pull request URL into organization, project, repository, and PR identifiers.
# Inputs: Azure DevOps pull request URL as the first positional argument.
# Outputs: Parsed identifier JSON on stdout; structured BLOCKER output on stderr when the URL is missing or invalid.
# Side effects: None.
set -euo pipefail

url="${1:-}"
if [[ -z "$url" ]]; then
  echo "BLOCKER:" >&2
  echo "code: MISSING_INPUT" >&2
  echo "required_input:" >&2
  echo "- Azure DevOps URL in the form https://dev.azure.com/<org>/<project>/_git/<repo>/pullrequest/<id>" >&2
  echo "next_question: Provide an Azure DevOps pull request URL or explicit identifiers." >&2
  exit 1
fi

pattern='^https://dev\.azure\.com/([^/]+)/([^/]+)/_git/([^/]+)/pullrequest/([0-9]+)(\?.*)?$'
if [[ "$url" =~ $pattern ]]; then
  jq -n \
    --arg organization "${BASH_REMATCH[1]}" \
    --arg project "${BASH_REMATCH[2]}" \
    --arg repository_id "${BASH_REMATCH[3]}" \
    --argjson pull_request_id "${BASH_REMATCH[4]}" \
    '{organization: $organization, project: $project, repository_id: $repository_id, pull_request_id: $pull_request_id}'
else
  echo "BLOCKER:" >&2
  echo "code: INVALID_PR_URL" >&2
  echo "required_input:" >&2
  echo "- Azure DevOps URL in the form https://dev.azure.com/<org>/<project>/_git/<repo>/pullrequest/<id>" >&2
  echo "next_question: Provide a valid Azure DevOps pull request URL or explicit identifiers." >&2
  exit 1
fi
