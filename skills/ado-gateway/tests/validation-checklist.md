# ADO Gateway — Validation Checklist

## Discovery Validation

- [ ] Frontmatter clearly triggers on Azure DevOps work item retrieval, PR comment retrieval, or PR URL parsing.
- [ ] Frontmatter clearly rejects write actions, GitHub review tasks, and OpenSpec authoring.

## Logic Validation

- [ ] Workflow distinguishes `work-item`, `pr-comments`, and `work-item-plus-pr-comments`.
- [ ] Missing PAT or identifiers produce blocker output.
- [ ] PR URL parsing is deterministic and limited to Azure DevOps URL shapes.
- [ ] The handoff contract names and field types are stable.

## Edge Cases

- [ ] Missing `System.Description` results in an empty string plus warning, not a fabricated summary.
- [ ] Missing acceptance criteria is reflected in `missing_fields`.
- [ ] Deleted PR comments remain represented with deletion flags.
- [ ] Missing line anchors remain `null`.
- [ ] Partial fetches mark `normalization.status: partial`.
