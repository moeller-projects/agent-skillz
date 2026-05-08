#!/usr/bin/env bash
# validate-handoff.sh
# Reads a contract JSON from stdin, validates it against the shared schema, and
# writes it to stdout unchanged.  Exits 1 and emits an ERROR block to stderr on
# any validation failure so callers can treat this as a simple pipe stage.
#
# Strategy:
#   1. Use Python jsonschema if available  (full Draft-2020-12 validation)
#   2. Fall back to a jq structural check  (required fields + enum values)
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
schema_file="$script_dir/../assets/schemas/ado-openspec-handoff.schema.json"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
cat > "$tmp"

# ── Strategy 1: Python jsonschema ────────────────────────────────────────────
if python3 -c "import jsonschema" 2>/dev/null; then
  python3 - "$schema_file" "$tmp" <<'PY'
import json
import sys

import jsonschema

schema_path, instance_path = sys.argv[1], sys.argv[2]

with open(schema_path, encoding="utf-8") as fh:
    schema = json.load(fh)
with open(instance_path, encoding="utf-8") as fh:
    instance = json.load(fh)

try:
    jsonschema.validate(instance, schema)
except jsonschema.ValidationError as exc:
    path = " → ".join(str(p) for p in exc.absolute_path) or "(root)"
    print("ERROR:", file=sys.stderr)
    print("code: NORMALIZATION_FAILED", file=sys.stderr)
    print("stage: emit", file=sys.stderr)
    print(f"message: Schema validation failed at {path}: {exc.message}", file=sys.stderr)
    print(
        "recovery: Check the emitted contract against "
        "assets/schemas/ado-openspec-handoff.schema.json",
        file=sys.stderr,
    )
    sys.exit(1)
PY

# ── Strategy 2: jq structural fallback ───────────────────────────────────────
else
  valid="$(jq -r '
    if (
      has("contract_version") and
      has("producer") and
      has("consumer") and
      has("artifact_type") and
      has("mode") and
      has("source") and
      has("normalization") and
      has("work_item") and
      has("pr_comments") and
      (.mode | . == "work-item" or . == "pr-comments" or . == "work-item-plus-pr-comments") and
      (.source | (
        has("platform") and has("organization") and has("project") and
        has("repository_id") and has("pull_request_id") and
        has("work_item_id") and (.read_only == true)
      )) and
      (.normalization.status | . == "pass" or . == "partial" or . == "fail")
    ) then "ok" else "fail" end
  ' "$tmp")"

  if [[ "$valid" != "ok" ]]; then
    echo "ERROR:" >&2
    echo "code: NORMALIZATION_FAILED" >&2
    echo "stage: emit" >&2
    echo "message: Contract failed structural validation (jq fallback -- install python3-jsonschema for full validation)." >&2
    echo "recovery: Check required fields and enum values against assets/schemas/ado-openspec-handoff.schema.json" >&2
    exit 1
  fi
fi

cat "$tmp"