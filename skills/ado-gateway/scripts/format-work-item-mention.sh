#!/usr/bin/env bash
# format-work-item-mention.sh
# Emits Azure DevOps work-item HTML @mention markup.
set -euo pipefail

"$(cd "$(dirname "$0")" && pwd)/ensure-env.sh"

mention_id=""
display_name=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mention-id|--user-id|--descriptor) mention_id="$2"; shift 2 ;;
    --display-name|--name) display_name="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

missing=()
[[ -z "$mention_id" ]] && missing+=(mention_id)
[[ -z "$display_name" ]] && missing+=(display_name)
if [[ ${#missing[@]} -gt 0 ]]; then
  echo "BLOCKER:" >&2
  echo "code: MISSING_INPUT" >&2
  echo "required_input:" >&2
  for item in "${missing[@]}"; do echo "- $item" >&2; done
  echo "next_question: Provide mention id/descriptor and display name to build the mention markup." >&2
  exit 1
fi

python3 - "$mention_id" "$display_name" <<'PY'
import html
import sys

mention_id = sys.argv[1]
display_name = sys.argv[2]
safe_id = html.escape(mention_id, quote=True)
safe_name = html.escape(display_name, quote=False)
print(f'<a href="#" data-vss-mention="version:2.0,{{{safe_id}}}">@{safe_name}</a>')
PY
