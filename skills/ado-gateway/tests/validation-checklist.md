# ADO Gateway — Validation Checklist

Status: executable validation added in `tests/run-validation.sh` and wired for CI in `.github/workflows/validate-ado-gateway.yml`.

## Discovery Validation

- [x] Frontmatter clearly triggers on Azure DevOps work item retrieval, PR comment retrieval, or PR URL parsing.
- [x] Frontmatter clearly rejects write actions, GitHub review tasks, and OpenSpec authoring.

## Logic Validation

- [x] Workflow distinguishes `work-item`, `pr-comments`, and `work-item-plus-pr-comments`.
- [x] Missing PAT or identifiers produce blocker output.
- [x] PR URL parsing is deterministic and limited to Azure DevOps URL shapes.
- [x] The handoff contract names and field types are stable.

## Edge Cases

- [x] Missing `System.Description` results in an empty string plus warning, not a fabricated summary.
- [x] Missing acceptance criteria is reflected in `normalization.warnings` as `acceptance criteria missing`.
- [x] Deleted PR comments remain represented with deletion flags.
- [x] Missing line anchors remain `null`.
- [x] Partial fetches mark `normalization.status: partial`.

## Automated Coverage

- [x] Example contracts validate against `assets/schemas/ado-openspec-handoff.schema.json`.
- [x] Invalid PR URLs produce `INVALID_PR_URL` blocker output.
- [x] `work_item.id` and `source.work_item_id` are numeric when known.
- [x] Stringified work item IDs are rejected by schema validation.
- [x] Emit path validates before writing to stdout.
- [x] Scripts are scanned for mutating curl requests.
