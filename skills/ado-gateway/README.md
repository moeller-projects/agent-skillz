# ADO Gateway

Version: 0.1.0

Read Azure DevOps work items and pull request discussions, normalize them, and emit a deterministic handoff contract for downstream skills.

## Includes

- read-only Azure DevOps work item retrieval
- Azure DevOps PR URL parsing and PR comment flattening
- normalized handoff contract for `openspec-gateway`
- safety boundaries for auth, raw payloads, and write actions
