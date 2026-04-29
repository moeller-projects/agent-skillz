# OpenSpec Gateway — Validation Checklist

## Discovery Validation

- [ ] Frontmatter clearly triggers on OpenSpec generation or governance.
- [ ] Frontmatter clearly rejects raw Azure DevOps retrieval and unrelated documentation tasks.

## Logic Validation

- [ ] Input is validated before generation.
- [ ] Missing risk tier produces blocker output.
- [ ] Overwrite attempts without approval produce blocker output.
- [ ] Validation, scoring, diff, and version helpers emit deterministic JSON or text outputs.
- [ ] `ci-gate.sh` is the only CI entrypoint.
- [ ] Generated specs include `## Review Context` before `## Open Questions`.

## Edge Cases

- [ ] Missing acceptance criteria become open questions rather than invented content.
- [ ] Baseline-unavailable flow sets `diff.available: false`.
- [ ] Duplicate FR or AC IDs reduce score or fail validation.
- [ ] Security redaction policy catches bearer tokens and PAT-like values.
- [ ] Public behavior changes are held for human approval.
