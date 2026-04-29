---
name: openspec-gateway
description: Use when generating or governing OpenSpec files from normalized requirements, refining an OpenSpec draft, or validating OpenSpec completeness and version/risk gates. Do not use when fetching raw Azure DevOps data, implementing code, or writing unrelated documentation.
title: OpenSpec Gateway
version: 0.1.0
summary: Consume normalized requirement input, generate OpenSpec files, and enforce deterministic validation, scoring, diff, and version gates.
---

# OpenSpec Gateway

## Purpose

Consume normalized requirement input, generate or update OpenSpec files, and enforce deterministic governance through validation, scoring, diff, and version gates.

## Use When

- Generating an OpenSpec file from normalized requirement input.
- Refining an OpenSpec draft while preserving version and risk governance.
- Validating an OpenSpec file for structure, requirement quality, and policy gates.
- Producing a governance artifact for review or CI.

## Avoid When

- The task is fetching raw Azure DevOps work items or PR comments.
- The task is implementing code with no spec output.
- The task is generic documentation work unrelated to OpenSpec.

## Workflow

1. Validate the handoff contract or direct structured input before generating anything.
2. Determine the risk tier and target spec name.
3. Generate or update the spec from normalized input.
4. Run validation, scoring, diff, and version checks.
5. Emit the governance artifact and downstream recommendations.
6. In CI, use only `scripts/ci-gate.sh`.

## Blocker Format

```text
BLOCKER:
code: <MISSING_HANDOFF|MISSING_INPUT|RISK_TIER_REQUIRED|BASELINE_REQUIRED|OVERWRITE_APPROVAL_REQUIRED>
required_input:
- ...
next_question: ...
```

## Error Format

```text
ERROR:
code: <INGEST_FAILED|GENERATE_FAILED|VALIDATION_FAILED|SCORING_FAILED|DIFF_FAILED|EMIT_FAILED>
stage: <ingest|generate|validate|score|diff|emit>
message: ...
recovery: ...
```

## Error Handling

1. Local: If no diff baseline is available, continue with `diff.available = false` and record the warning.
2. Flow: Block on malformed handoff input, missing risk tier, or failed validation.
3. Recovery: Show intended file changes before overwrite. If validation fails after generation, revert only the files created or changed by this skill.

## Human-in-the-Loop

Request explicit approval before:

- Overwriting an existing spec file.
- Accepting a major version bump.
- Removing existing functional requirements or acceptance criteria.
- Finalizing a spec that changes public behavior or API contracts.

## Validation Checklist

- [ ] Frontmatter triggers on OpenSpec generation and governance, not raw Azure DevOps fetches.
- [ ] The workflow validates input before generation.
- [ ] The generated spec includes `Version:` and `Risk Tier:` near the top.
- [ ] Validation, scoring, diff, and version checks all produce deterministic outputs.
- [ ] CI entrypoint is limited to `scripts/ci-gate.sh`.

See `tests/validation-checklist.md` for the full checklist.

## Assets

- `assets/schemas/ado-openspec-handoff.schema.json` — shared handoff schema
- `assets/schemas/openspec-artifact.schema.json` — governance artifact schema
- `assets/templates/spec.md` — OpenSpec template
- `assets/templates/artifact.json` — governance artifact template
- `assets/examples/` — sample handoff, spec, and artifact files

## References

- `references/workflow.md` — detailed workflow
- `references/governance.md` — risk, scoring, diff, and version rules
- `references/review-and-hitl.md` — approval gates and overwrite rules
- `references/handoff-contract.md` — contract requirements for input
- `references/end-to-end.md` — bash-only walkthrough from normalized handoff to gated spec artifact

## Rules

- `rules/_sections.md`
- `rules/handoff-consumption.md`
- `rules/version-and-risk-gates.md`
- `rules/ci-entrypoint.md`
