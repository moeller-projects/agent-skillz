#!/usr/bin/env bash
set -euo pipefail

input="${1:-}"
if [[ -z "$input" ]]; then
  echo "spec"
  exit 0
fi

slug="$(printf '%s' "$input" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/<[^>]+>//g; s/[^a-z0-9]+/-/g; s/^-+|-+$//g; s/-+/-/g')"

if [[ -z "$slug" ]]; then
  slug="spec"
fi

echo "${slug:0:64}"
