# Workflow

## Read Flow

1. Determine whether the request targets a work item, PR comments, or both.
2. Resolve identifiers from explicit inputs first; if a pull request URL is supplied, parse it into organization, project, repository, and pull request ID.
3. Validate required auth and command dependencies with `scripts/ensure-env.sh`.
4. Fetch Azure DevOps data with GET-only bash helpers.
5. Normalize the work item payload with `scripts/normalize-work-item.sh`.
6. Emit the contract with `scripts/emit-handoff.sh`, or run the full bash-only happy path through `scripts/generate-handoff.sh`.

## Write Flow

1. Confirm the user requested one of the supported write actions.
2. Generate dry-run output first.
3. Review the dry-run payload for endpoint, method, request body, and required PAT scope.
4. Execute only with `--execute --confirm-write I_UNDERSTAND_THIS_WRITES_TO_ADO`.
5. Return the Azure DevOps response or structured `WRITE_FAILED` error.

## Partial Flow

1. If one read source succeeds and the other source is unavailable, emit `normalization.status: partial`.
2. Record unavailable fields in `normalization.missing_fields`.
3. Do not fabricate missing values.

## Abort Conditions

- Missing PAT or auth env var for network calls
- Malformed PR URL
- Missing work item ID or pull request ID
- Unsupported write action
- Write execution requested without explicit confirmation token
