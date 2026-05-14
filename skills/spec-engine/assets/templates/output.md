# Spec Engine — Output Template

## Default (spec + quality_gates + open_questions)

```text
spec:
- goal: <one sentence — the outcome the feature must achieve>
- scope:
  - IN: <what is included>
  - OUT: <what is explicitly excluded>
- requirements:
  - REQ-01: <requirement statement — testable, no ambiguity>
  - REQ-02: <requirement statement>
- acceptance_criteria:
  - AC-01 (REQ-01): GIVEN <precondition> WHEN <action> THEN <observable outcome>
  - AC-02 (REQ-01): GIVEN <precondition> WHEN <action> THEN <observable outcome>

quality_gates:
- [ ] <policy or governance check>

risk_tier: <Low | Medium | High | Critical>

open_questions:
- OQ-01: <question> — owner: <person or team> — due: <date or milestone>
```

## Diff Format (spec version change)

```text
spec-diff:
  version: <old> → <new>
  changes:
  - REQ-XX: <what changed>
  - AC-XX: <what changed>
  reason: <why the spec changed>
  baseline: <reference to prior version>
```

## OpenSpec Output (`output_format: openspec`)

```text
output_format: openspec
openspec_proposal:
  path: proposals/
  change_path: openspec/changes/<change-name>/
  metadata_file: .openspec.yaml
  proposal_file: proposal.md
  delta_spec_files:
  - specs/<capability>/spec.md

.openspec.yaml:
  schema: spec-driven
  created: YYYY-MM-DD

proposal.md:
  sections:
  - Why
  - What Changes
  - Capabilities
  - Impact

specs/<capability>/spec.md:
  allowed_delta_headers:
  - ADDED Requirements
  - MODIFIED Requirements
  - REMOVED Requirements
  - RENAMED Requirements
```

## Rules

- Every requirement must be testable: no "should", "might", or "as needed".
- Every acceptance criterion must follow GIVEN/WHEN/THEN format.
- Every conflicting requirement must be surfaced as an open question, not silently resolved.
- Out-of-scope items must be explicit; do not leave scope ambiguous.
- OpenSpec output must keep the authored requirement intent while changing only serialization format.
