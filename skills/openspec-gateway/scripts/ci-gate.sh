#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
spec_file="${1:?spec file required}"
baseline_file="${2:-}"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

validation_file="$work_dir/validation.json"
score_file="$work_dir/score.json"
diff_file="$work_dir/diff.json"
version_file="$work_dir/version.json"
artifact_file="$work_dir/artifact.json"

"$script_dir/validate-spec.sh" "$spec_file" > "$validation_file"
"$script_dir/score-spec.sh" "$spec_file" > "$score_file"
"$script_dir/diff-spec.sh" "$spec_file" "$baseline_file" > "$diff_file"
"$script_dir/enforce-version.sh" "$spec_file" "$diff_file" "$baseline_file" > "$version_file"
"$script_dir/emit-artifact.sh" "$spec_file" "$validation_file" "$score_file" "$diff_file" "$version_file" > "$artifact_file"

cat "$artifact_file"
