# ADO Gateway

Version: 0.4.0

Read Azure DevOps work items and pull request discussions, normalize them, and perform a small approved set of write actions through deterministic dry-run-first scripts.

## Includes

- read-only Azure DevOps work item retrieval
- Azure DevOps PR URL parsing, PR branch/work item enrichment, and PR comment flattening
- normalized handoff contract for `spec-engine`
- guarded write actions for creating work items, creating work item comments, creating PRs, and adding/replying to PR comments
- dry-run JSON action plans before any mutation
- explicit `--confirm` gate for every write script

## Read flow

```bash
export AZURE_DEVOPS_PAT=...

./scripts/generate-handoff.sh \
  --pull-request-url "https://dev.azure.com/example-org/example-project/_git/example-repo/pullrequest/123" \
  --work-item-id 456
```

## Write flow: dry run first

```bash
./scripts/create-work-item.sh \
  --organization example-org \
  --project example-project \
  --type Bug \
  --title "Checkout fails for invalid coupon" \
  --description "Observed during checkout validation."
```

## Write flow: execute after review

```bash
./scripts/create-work-item.sh \
  --organization example-org \
  --project example-project \
  --type Bug \
  --title "Checkout fails for invalid coupon" \
  --description "Observed during checkout validation." \
  --confirm
```

See `references/write-actions.md` for supported mutation scripts.
