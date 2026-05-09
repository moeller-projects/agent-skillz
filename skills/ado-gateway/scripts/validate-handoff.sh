#!/usr/bin/env bash
# validate-handoff.sh
# Reads a contract JSON from stdin, validates it against the shared schema, and
# writes it to stdout unchanged. Exits 1 and emits an ERROR block to stderr on
# validation failure.
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
schema_file="$script_dir/../assets/schemas/ado-openspec-handoff.schema.json"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
cat > "$tmp"

python3 - "$schema_file" "$tmp" <<'PY'
import json
import sys
from typing import Any, Dict, List

schema_path, instance_path = sys.argv[1], sys.argv[2]

with open(schema_path, encoding="utf-8") as fh:
    schema = json.load(fh)
with open(instance_path, encoding="utf-8") as fh:
    instance = json.load(fh)


def type_name(value: Any) -> str:
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "boolean"
    if isinstance(value, int) and not isinstance(value, bool):
        return "integer"
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return "number"
    if isinstance(value, str):
        return "string"
    if isinstance(value, list):
        return "array"
    if isinstance(value, dict):
        return "object"
    return type(value).__name__


def type_matches(value: Any, expected: str) -> bool:
    actual = type_name(value)
    if expected == "number":
        return actual in {"integer", "number"}
    return actual == expected


def walk(value: Any, node: Dict[str, Any], path: List[str]) -> None:
    if "const" in node and value != node["const"]:
        raise ValueError(path, f"expected constant {node['const']!r}, got {value!r}")
    if "enum" in node and value not in node["enum"]:
        raise ValueError(path, f"expected one of {node['enum']!r}, got {value!r}")
    if "type" in node:
        expected = node["type"]
        expected_types = expected if isinstance(expected, list) else [expected]
        if not any(type_matches(value, item) for item in expected_types):
            raise ValueError(path, f"expected type {expected_types!r}, got {type_name(value)!r}")
    if type_name(value) == "object":
        for key in node.get("required", []):
            if key not in value:
                raise ValueError(path, f"missing required property {key!r}")
        properties = node.get("properties", {})
        if node.get("additionalProperties") is False:
            extra = sorted(set(value) - set(properties))
            if extra:
                raise ValueError(path, f"unexpected properties {extra!r}")
        for key, child in properties.items():
            if key in value:
                walk(value[key], child, path + [key])
    if type_name(value) == "array" and "items" in node:
        for index, item in enumerate(value):
            walk(item, node["items"], path + [str(index)])


try:
    walk(instance, schema, [])
except ValueError as err:
    path, message = err.args
    location = " → ".join(path) or "(root)"
    print("ERROR:", file=sys.stderr)
    print("code: NORMALIZATION_FAILED", file=sys.stderr)
    print("stage: emit", file=sys.stderr)
    print(f"message: Schema validation failed at {location}: {message}", file=sys.stderr)
    print("recovery: Check the emitted contract against assets/schemas/ado-openspec-handoff.schema.json", file=sys.stderr)
    sys.exit(1)
PY

cat "$tmp"
