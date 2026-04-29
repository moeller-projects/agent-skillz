# Workflow

## Default Flow

1. Determine whether the request targets a work item, PR comments, or both.
2. Resolve identifiers from explicit inputs first; if a pull request URL is supplied, parse it into organization, project, repository, and pull request ID.
3. Validate required auth and command dependencies.
4. Fetch Azure DevOps data with GET-only helpers.
5. Normalize the payload into the shared handoff contract.
6. Emit the contract and stop.

## Partial Flow

1. If one source succeeds and the other source is unavailable, emit `normalization.status: partial`.
2. Record unavailable fields in `normalization.missing_fields`.
3. Do not fabricate missing values.

## Abort Conditions

- Missing PAT or auth env var
- Malformed PR URL
- Missing work item ID or pull request ID
- Non-read-only action request
