#!/usr/bin/env bash
set -euo pipefail

tmp_json="$(mktemp)"
trap 'rm -f "$tmp_json"' EXIT
cat > "$tmp_json"

python3 - "$tmp_json" <<'PY'
import html
import json
import re
import sys
from html.parser import HTMLParser


class TextExtractor(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []

    def handle_starttag(self, tag, attrs):
        if tag == "br":
            self.parts.append("\n")
        elif tag == "li":
            self.parts.append("\n- ")

    def handle_endtag(self, tag):
        if tag in {"p", "div", "ul", "ol", "li"}:
            self.parts.append("\n")

    def handle_data(self, data):
        self.parts.append(data)


def redact_tokens(value: str) -> str:
    value = re.sub(r"(Bearer\s+)[A-Za-z0-9._-]+", r"\1[REDACTED]", value, flags=re.IGNORECASE)
    value = re.sub(r"\b(?:ghp_[A-Za-z0-9]+|AZURE_DEVOPS_PAT|[A-Za-z0-9]{20,}\.[A-Za-z0-9._-]{10,})\b", "[REDACTED]", value)
    return value


def normalize_html(value: str) -> str:
    if not value:
        return ""
    parser = TextExtractor()
    parser.feed(value)
    text = html.unescape("".join(parser.parts))
    text = re.sub(r"\r\n?", "\n", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return redact_tokens(text.strip())


with open(sys.argv[1], "r", encoding="utf-8") as fh:
    payload = json.load(fh)
fields = payload.get("fields", {})
work_item_type = fields.get("System.WorkItemType", "")


def get_field(*names: str) -> str:
    for name in names:
        value = fields.get(name)
        if value is not None:
            return str(value)
    return ""


repro = ""
system_info = ""
if work_item_type == "Bug":
    repro = normalize_html(get_field("Microsoft.VSTS.TCM.ReproSteps", "Custom.ReproSteps"))
    system_info = normalize_html(get_field("Microsoft.VSTS.TCM.SystemInfo", "Custom.SystemInfo"))

work_item_id = payload.get("id")
if isinstance(work_item_id, str) and work_item_id.isdigit():
    work_item_id = int(work_item_id)
elif not isinstance(work_item_id, int):
    work_item_id = None

normalized = {
    "id": work_item_id,
    "type": work_item_type,
    "title": redact_tokens(get_field("System.Title")),
    "description": normalize_html(get_field("System.Description")),
    "acceptance_criteria": normalize_html(get_field("Microsoft.VSTS.Common.AcceptanceCriteria", "Custom.AcceptanceCriteria")),
    "repro_steps": repro,
    "system_info": system_info,
    "tags": get_field("System.Tags"),
    "state": get_field("System.State"),
}

json.dump(normalized, sys.stdout, indent=2)
sys.stdout.write("\n")
PY
