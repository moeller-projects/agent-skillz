---
name: ado-gateway
description: Use when fetching Azure DevOps work items or pull request comments, parsing Azure DevOps pull request URLs, or normalizing read-only Azure DevOps data for downstream skills. Do not use when editing Azure DevOps state, reviewing GitHub pull requests, or authoring OpenSpec files.
title: ADO Gateway
version: 0.1.0
summary: Read Azure DevOps work items and PR discussions, normalize them, and emit a deterministic handoff contract for downstream skills.
allowed-tools:
  - read_file
  - shell
---

# ADO Gateway

## Purpose

Fetch Azure DevOps work item and pull request discussion data through read-only flows, normalize the result, and emit a stable handoff contract for downstream skills.

## Use When

- Fetching a backlog item or work item from Azure DevOps.
- Fetching pull request comments from an Azure DevOps PR URL or explicit identifiers.
- Parsing an Azure DevOps pull request URL into organization, project, repository, and pull request ID.
- Converting Azure DevOps data into a deterministic contract for another skill.

## Avoid When

- The task requires posting comments, updating work items, or any other Azure DevOps write action.
- The task is a GitHub pull request review.
- The task is generating or validating an OpenSpec file.
- The task is generic REST API work with no Azure DevOps context.

## Workflow

1. Identify the source mode: `work-item`, `pr-comments`, or `work-item-plus-pr-comments`.
2. Validate required identifiers and authentication. Accept either explicit Azure DevOps identifiers or a pull request URL.
3. Fetch Azure DevOps data with GET requests only.
4. Normalize HTML fields, comment threads, line anchors, and missing values into the shared contract.
5. Emit contract JSON and stop. Do not draft specs or take write actions.

## Output Contract

Return only the shared handoff envelope:

```json
{
  "contract_version": "1.0.0",
  "producer": "ado-gateway",
  "consumer": "openspec-gateway",
  "artifact_type": "ado-normalized",
  "mode": "work-item|pr-comments|work-item-plus-pr-comments",
  "source": {
    "platform": "azure-devops",
    "organization": "",
    "project": "",
    "repository_id": "",
    "pull_request_id": null,
    "work_item_id": null,
    "read_only": true
  },
  "normalization": {
    "status": "pass|partial|fail",
    "missing_fields": [],
    "warnings": [],
    "html_stripped": true,
    "secret_redactions_applied": true
  },
  "work_item": {},
  "pr_comments": []
}
```

## Blocker Format

```text
BLOCKER:
code: <MISSING_INPUT|MISSING_AUTH|INVALID_PR_URL|NETWORK_UNAVAILABLE>
required_input:
- ...
next_question: ...
```

## Error Format

```text
ERROR:
code: <FETCH_FAILED|PARSE_FAILED|NORMALIZATION_FAILED>
stage: <fetch|parse|normalize|emit>
message: ...
recovery: ...
```

## Error Handling

1. Local: If one source is unavailable but the other source succeeds, emit `normalization.status = partial` and list the missing fields.
2. Flow: Abort on missing authentication, invalid identifiers, or malformed PR URLs.
3. Recovery: No rollback is required because the skill is read-only.

## Human-in-the-Loop

Request explicit approval before:

- Using inferred organization, project, or repository values that were not supplied.
- Returning raw Azure DevOps thread payloads.
- Adding any Azure DevOps mutation step.

## Validation Checklist

- [ ] Frontmatter clearly limits the skill to Azure DevOps read-only retrieval and normalization.
- [ ] Workflow accepts either a PR URL or explicit identifiers.
- [ ] Output matches the shared handoff contract with stable field names.
- [ ] Missing auth or malformed inputs produce blocker output instead of guesses.
- [ ] No POST, PATCH, PUT, or DELETE action appears anywhere in the skill.

See `tests/validation-checklist.md` for the full checklist.

## Assets

- `assets/schemas/ado-openspec-handoff.schema.json` — shared handoff schema
- `assets/templates/handoff.json` — minimal contract template
- `assets/templates/blocker.txt` — blocker output shape
- `assets/templates/error.txt` — error output shape
- `assets/examples/` — example work item and PR comment payloads

## References

- `references/workflow.md` — detailed execution flow
- `references/auth-and-safety.md` — auth handling and safety boundaries
- `references/normalization-rules.md` — field extraction and normalization rules
- `references/handoff-contract.md` — producer requirements for downstream skills

## Rules

- `rules/_sections.md`
- `rules/read-only-boundary.md`
- `rules/normalization-precedence.md`
