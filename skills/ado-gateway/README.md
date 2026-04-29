# ADO Gateway

Version: 0.1.0

Read Azure DevOps work items and pull request discussions, normalize them, and emit a deterministic handoff contract for downstream skills.

## Includes

- read-only Azure DevOps work item retrieval
- Azure DevOps PR URL parsing and PR comment flattening
- normalized handoff contract for `openspec-gateway`
- safety boundaries for auth, raw payloads, and write actions

## Quick start

```bash
export AZURE_DEVOPS_PAT=...

./scripts/generate-handoff.sh \
  --pull-request-url "https://dev.azure.com/example-org/example-project/_git/example-repo/pullrequest/123" \
  --work-item-id 456
```

```bash
./scripts/generate-handoff.sh \
  --organization example-org \
  --project example-project \
  --repository-id example-repo \
  --pull-request-id 123 \
  --work-item-id 456
```

See `references/end-to-end.md` for the full bash-only flow into `openspec-gateway`.
