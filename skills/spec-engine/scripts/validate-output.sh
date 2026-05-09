#!/usr/bin/env bash
set -euo pipefail

INPUT="$(cat)"
ERRORS=()

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

for SECTION in spec quality_gates open_questions; do
  if ! printf '%s\n' "$INPUT" | grep -qE "^${SECTION}:"; then
    ERRORS+=("missing section: ${SECTION}:")
  fi
done

SPEC_SECTION="$(extract_section "spec")"
OPEN_QUESTIONS_SECTION="$(extract_section "open_questions")"

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

  if printf '%s\n' "$REQUIREMENTS_SECTION" | grep -qiE '\b(should|might|as needed|where appropriate)\b'; then
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
      if [[ ! "$AC_LINE" =~ ^[[:space:]]*-[[:space:]](AC-[0-9][0-9]*)[[:space:]]\((REQ-[0-9][0-9]*)\):[[:space:]]+GIVEN[[:space:]]+.+[[:space:]]+WHEN[[:space:]]+.+[[:space:]]+THEN[[:space:]]+.+$ ]]; then
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

if [ ${#ERRORS[@]} -gt 0 ]; then
  echo "INVALID output:"
  for ERR in "${ERRORS[@]}"; do
    echo "  - $ERR"
  done
  exit 1
fi

echo "OK"
