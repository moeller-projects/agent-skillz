#!/usr/bin/env bash
# check-skill-output-contracts.sh
# Purpose: Ensure each skill has an output template and validate concrete example output blocks against that skill's validator.
# Inputs: Repository working tree containing skills/*/scripts/validate-output.sh and markdown assets.
# Outputs: PASS/FAIL lines to stdout/stderr; exits non-zero on the first contract drift.
# Side effects: Creates and removes temporary files only.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
skills_dir="$repo_root/skills"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

extract_text_blocks() {
  local markdown_file="$1"
  local output_dir="$2"

  awk -v output_dir="$output_dir" '
    BEGIN { in_block = 0; block = 0 }
    /^```text$/ {
      in_block = 1
      block++
      next
    }
    /^```$/ && in_block {
      in_block = 0
      next
    }
    in_block {
      print >> (output_dir "/block-" block ".txt")
    }
  ' "$markdown_file"
}

validated_files=0

for skill_dir in "$skills_dir"/*; do
  [[ -d "$skill_dir" ]] || continue

  validator="$skill_dir/scripts/validate-output.sh"
  template="$skill_dir/assets/templates/output.md"
  examples_dir="$skill_dir/assets/examples"

  if [[ ! -f "$validator" || ! -f "$template" ]]; then
    continue
  fi

  skill_name="$(basename "$skill_dir")"
  template_block_dir="$tmp_dir/${skill_name}-template"
  mkdir -p "$template_block_dir"
  extract_text_blocks "$template" "$template_block_dir"

  shopt -s nullglob
  template_blocks=("$template_block_dir"/block-*.txt)
  shopt -u nullglob

  if [[ ${#template_blocks[@]} -eq 0 ]]; then
    fail "$skill_name $(basename "$template") contains no output blocks"
  fi

  example_files=()
  if [[ -d "$examples_dir" ]]; then
    while IFS= read -r example_file; do
      example_files+=("$example_file")
    done < <(find "$examples_dir" -maxdepth 1 -type f -name '*.md' | sort)
  fi

  if [[ ${#example_files[@]} -eq 0 ]]; then
    pass "$skill_name template output blocks present; validator skipped because no concrete examples exist"
    continue
  fi

  for markdown_file in "${example_files[@]}"; do
    block_dir="$tmp_dir/${skill_name}-$(basename "$markdown_file" .md)"
    mkdir -p "$block_dir"
    extract_text_blocks "$markdown_file" "$block_dir"

    shopt -s nullglob
    blocks=("$block_dir"/block-*.txt)
    shopt -u nullglob

    if [[ ${#blocks[@]} -eq 0 ]]; then
      fail "$skill_name $(basename "$markdown_file") contains no output blocks"
    fi

    for block_file in "${blocks[@]}"; do
      if ! bash "$validator" < "$block_file" > "$block_dir/result.out" 2>&1; then
        {
          printf 'Validator failed for %s (%s, %s)\n' "$skill_name" "$(basename "$markdown_file")" "$(basename "$block_file")"
          cat "$block_dir/result.out"
        } >&2
        exit 1
      fi
      validated_files=$((validated_files + 1))
    done
  done

  pass "$skill_name template present and examples match validator"
done

printf '\nValidated %d example output block(s).\n' "$validated_files"
