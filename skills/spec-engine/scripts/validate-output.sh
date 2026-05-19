#!/usr/bin/env bash
# validate-output.sh
# Purpose: Validate Spec Engine freeform spec and OpenSpec proposal outputs.
# Inputs: Contract text on stdin.
# Outputs: "OK" on stdout when valid; validation errors on stdout when invalid.
# Side effects: None.
set -euo pipefail

INPUT="$(cat)"
ERRORS=()

# Banned words that make requirements untestable (mirrors requirement-quality.md)
BANNED_WORDS=(
  should might maybe
  "as needed" "where appropriate"
  "etc" "and so on"
  user-friendly better faster seamless intuitive
)

build_banned_regex() {
  local joined
  joined="$(IFS='|'; printf '%s' "${BANNED_WORDS[*]}")"
  printf '%s' "\\b(${joined})\\b"
}

extract_section() {
  local section="$1"
  printf '%s\n' "$INPUT" | awk -v section="$section" '
    $0 == section ":" { in_section = 1; next }
    in_section && $0 ~ /^[A-Za-z_][A-Za-z0-9_-]*:$/ { exit }
    in_section { print }
  '
}

extract_spec_subsection() {
  local subsection="$1"
  printf '%s\n' "$SPEC_SECTION" | awk -v subsection="$subsection" '
    $0 ~ "^- " subsection ":$" { in_section = 1; next }
    in_section && $0 ~ /^- [A-Za-z_]+:$/ { exit }
    in_section { print }
  '
}

extract_openspec_proposal_section() {
  printf '%s\n' "$INPUT" | awk '
    $0 == "openspec_proposal:" { in_section = 1; next }
    in_section && $0 ~ /^[^[:space:]].*:[[:space:]]*$/ { exit }
    in_section { print }
  '
}

extract_named_block() {
  local block_name="$1"
  printf '%s\n' "$INPUT" | awk -v block_name="$block_name" '
    $0 == block_name ":" { in_block = 1; next }
    in_block && $0 ~ /^[^[:space:]].*:[[:space:]]*$/ { exit }
    in_block { print }
  '
}

extract_openspec_field_value() {
  local field="$1"
  printf '%s\n' "$OPENSPEC_PROPOSAL_SECTION" | sed -n "s/^  ${field}:[[:space:]]*//p" | head -1
}

extract_openspec_delta_paths() {
  printf '%s\n' "$OPENSPEC_PROPOSAL_SECTION" | awk '
    /^  delta_spec_files:$/ { in_list = 1; next }
    in_list && /^  [a-zA-Z0-9_-]+:/ { exit }
    in_list && /^  - / { sub(/^  - /, ""); print; next }
    in_list && /^  / { next }
    in_list && !/^  / { exit }
  '
}

validate_openspec_delta_block() {
  local delta_path="$1"
  local delta_block="$2"
  mapfile -t DELTA_ERRORS < <(printf '%s\n' "$delta_block" | awk -v delta_path="$delta_path" '
    function flush_requirement() {
      if (!in_requirement) {
        return
      }
      if (requirement_section == "ADDED" || requirement_section == "MODIFIED") {
        if (!requirement_has_normative) {
          printf "%s: requirement \"%s\" in %s must include SHALL or MUST\n", delta_path, requirement_name, requirement_section
        }
        if (requirement_scenarios < 1) {
          printf "%s: requirement \"%s\" in %s must include at least one #### Scenario:\n", delta_path, requirement_name, requirement_section
        }
      }
      in_requirement = 0
      requirement_name = ""
      requirement_has_normative = 0
      requirement_scenarios = 0
    }
    BEGIN {
      current_section = ""
      has_delta_header = 0
      has_requirement_header = 0
      in_requirement = 0
      requirement_name = ""
      requirement_section = ""
      requirement_has_normative = 0
      requirement_scenarios = 0
    }
    /^## (ADDED|MODIFIED|REMOVED|RENAMED) Requirements$/ {
      flush_requirement()
      has_delta_header = 1
      if (match($0, /^## ([A-Z]+) Requirements$/, section_parts)) {
        current_section = section_parts[1]
      } else {
        current_section = ""
      }
      next
    }
    /^### Requirement:/ {
      flush_requirement()
      has_requirement_header = 1
      in_requirement = 1
      requirement_section = current_section
      requirement_name = $0
      sub(/^### Requirement:[[:space:]]*/, "", requirement_name)
      next
    }
    in_requirement {
      if ($0 ~ /^#### Scenario:/) {
        requirement_scenarios++
        next
      }
      # Match SHALL/MUST as standalone tokens, not inside alphanumeric/underscore/hyphen compounds.
      if ((requirement_section == "ADDED" || requirement_section == "MODIFIED") &&
          $0 ~ /(^|[^[:alnum:]_-])(SHALL|MUST)($|[^[:alnum:]_-])/) {
        requirement_has_normative = 1
      }
    }
    END {
      flush_requirement()
      if (!has_delta_header) {
        print delta_path ": must include at least one delta section header"
      }
      if (!has_requirement_header) {
        print delta_path ": must include at least one ### Requirement: entry"
      }
    }
  ')
  for DELTA_ERROR in "${DELTA_ERRORS[@]}"; do
    ERRORS+=("OpenSpec delta spec $DELTA_ERROR")
  done
}

validate_freeform() {
  for SECTION in spec quality_gates open_questions risk_tier; do
    if ! printf '%s\n' "$INPUT" | grep -qE "^${SECTION}:"; then
      ERRORS+=("missing section: ${SECTION}:")
    fi
  done

  SPEC_SECTION="$(extract_section "spec")"
  OPEN_QUESTIONS_SECTION="$(extract_section "open_questions")"

  RISK_TIER_VALUE="$(printf '%s\n' "$INPUT" | grep -E '^risk_tier:' | sed 's/^risk_tier:[[:space:]]*//' | head -1 || true)"
  if [ -n "$RISK_TIER_VALUE" ] && ! printf '%s\n' "$RISK_TIER_VALUE" | grep -qE '^(Low|Medium|High|Critical)$'; then
    ERRORS+=("risk_tier must be one of: Low, Medium, High, Critical")
  fi

  if [ -n "$SPEC_SECTION" ]; then
    SCOPE_SECTION="$(extract_spec_subsection "scope")"
    REQUIREMENTS_SECTION="$(extract_spec_subsection "requirements")"
    ACCEPTANCE_CRITERIA_SECTION="$(extract_spec_subsection "acceptance_criteria")"

    if ! printf '%s\n' "$SCOPE_SECTION" | grep -qE '^[[:space:]]*- IN:'; then
      ERRORS+=("missing IN scope entry")
    fi

    if ! printf '%s\n' "$SCOPE_SECTION" | grep -qE '^[[:space:]]*- OUT:'; then
      ERRORS+=("missing OUT scope entry")
    fi

    mapfile -t REQ_IDS < <(printf '%s\n' "$REQUIREMENTS_SECTION" | sed -n 's/^[[:space:]]*- \(REQ-[0-9][0-9]*\):.*/\1/p')
    if [ ${#REQ_IDS[@]} -eq 0 ]; then
      ERRORS+=("requirements must include at least one REQ-XX item")
    fi

    if printf '%s\n' "$REQUIREMENTS_SECTION" | grep -qiE "$(build_banned_regex)"; then
      ERRORS+=("requirements must be testable; found vague language in requirements")
    fi

    if [ ${#REQ_IDS[@]} -gt 0 ]; then
      duplicate_req_ids="$(printf '%s\n' "${REQ_IDS[@]}" | sort | uniq -d || true)"
      if [ -n "$duplicate_req_ids" ]; then
        ERRORS+=("requirements must use unique REQ-XX identifiers")
      fi
    fi

    mapfile -t AC_LINES < <(printf '%s\n' "$ACCEPTANCE_CRITERIA_SECTION" | grep -E '^[[:space:]]*- AC-' || true)
    if [ ${#AC_LINES[@]} -eq 0 ]; then
      ERRORS+=("acceptance criteria must include at least one AC-XX item")
    else
      for AC_LINE in "${AC_LINES[@]}"; do
        if [[ ! "$AC_LINE" =~ ^[[:space:]]*-[[:space:]]+(AC-[0-9][0-9]*)[[:space:]]+\((REQ-[0-9][0-9]*)\)[[:space:]]*:[[:space:]]+GIVEN[[:space:]]+.+[[:space:]]+WHEN[[:space:]]+.+[[:space:]]+THEN[[:space:]]+.+$ ]]; then
          ERRORS+=("acceptance criteria must use AC-XX (REQ-XX): GIVEN ... WHEN ... THEN ... format")
          continue
        fi

        referenced_req="${BASH_REMATCH[2]}"
        if ! printf '%s\n' "${REQ_IDS[@]}" | grep -qx "$referenced_req"; then
          ERRORS+=("acceptance criteria must reference an existing REQ-XX item")
        fi
      done
    fi
  fi

  if printf '%s\n' "$OPEN_QUESTIONS_SECTION" | grep -qE '^[[:space:]]*- OQ-'; then
    while IFS= read -r OQ_LINE; do
      [ -z "$OQ_LINE" ] && continue
      if [[ ! "$OQ_LINE" =~ ^[[:space:]]*-[[:space:]]OQ-[0-9][0-9]*:.*[[:space:]]—[[:space:]]owner:\ .+[[:space:]]—[[:space:]]due:\ .+$ ]]; then
        ERRORS+=("open questions must include OQ-XX with owner and due date")
        break
      fi
    done < <(printf '%s\n' "$OPEN_QUESTIONS_SECTION" | grep -E '^[[:space:]]*- OQ-' || true)
  fi
}

validate_openspec() {
  if ! printf '%s\n' "$INPUT" | grep -qE '^output_format:[[:space:]]*openspec$'; then
    ERRORS+=("OpenSpec output must set output_format: openspec")
  fi

  if ! printf '%s\n' "$INPUT" | grep -qE '^openspec_proposal:$'; then
    ERRORS+=("OpenSpec output missing openspec_proposal")
  fi

  OPENSPEC_PROPOSAL_SECTION="$(extract_openspec_proposal_section)"

  for FIELD in path change_path metadata_file proposal_file delta_spec_files; do
    if ! printf '%s\n' "$OPENSPEC_PROPOSAL_SECTION" | grep -qE "^  ${FIELD}:"; then
      ERRORS+=("OpenSpec output missing openspec_proposal.${FIELD}")
    fi
  done

  if ! printf '%s\n' "$OPENSPEC_PROPOSAL_SECTION" | grep -qE '^  metadata_file:[[:space:]]*\.openspec\.yaml$'; then
    ERRORS+=("OpenSpec output must use metadata_file: .openspec.yaml")
  fi

  if printf '%s\n' "$OPENSPEC_PROPOSAL_SECTION" | grep -qE 'change\.yaml'; then
    ERRORS+=("OpenSpec output must not emit change.yaml for v1.3.1")
  fi

  PROPOSAL_FILE="$(extract_openspec_field_value "proposal_file")"
  if [ -n "$PROPOSAL_FILE" ]; then
    PROPOSAL_BLOCK="$(extract_named_block "$PROPOSAL_FILE")"
    if [ -z "$PROPOSAL_BLOCK" ]; then
      ERRORS+=("OpenSpec output missing block: ${PROPOSAL_FILE}")
    else
      for HEADER in "## Why" "## What Changes" "## Capabilities" "## Impact"; do
        if ! printf '%s\n' "$PROPOSAL_BLOCK" | grep -qF "$HEADER"; then
          ERRORS+=("OpenSpec ${PROPOSAL_FILE} missing section: $HEADER")
        fi
      done
    fi
  fi

  mapfile -t DELTA_SPEC_PATHS < <(extract_openspec_delta_paths)
  if [ ${#DELTA_SPEC_PATHS[@]} -eq 0 ]; then
    ERRORS+=("OpenSpec output must include at least one openspec_proposal.delta_spec_files entry")
  fi

  for DELTA_PATH in "${DELTA_SPEC_PATHS[@]}"; do
    DELTA_BLOCK="$(extract_named_block "$DELTA_PATH")"
    if [ -z "$DELTA_BLOCK" ]; then
      ERRORS+=("OpenSpec output missing block: ${DELTA_PATH}")
      continue
    fi
    validate_openspec_delta_block "$DELTA_PATH" "$DELTA_BLOCK"
  done

}

if printf '%s\n' "$INPUT" | grep -qE '^output_format:[[:space:]]*openspec$'; then
  validate_openspec
else
  validate_freeform
fi

if [ ${#ERRORS[@]} -gt 0 ]; then
  echo "INVALID output:"
  for ERR in "${ERRORS[@]}"; do
    echo "  - $ERR"
  done
  exit 1
fi

echo "OK"
