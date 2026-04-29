# Workflow

## Default Flow

1. Validate the handoff or direct input shape before generation.
2. Determine risk tier, version, and target spec path.
3. Generate or update the spec using the template and normalized inputs.
4. Run validation gates, score the spec, diff against a baseline when available, and enforce version rules.
5. Emit the governance artifact even when gates fail so the caller receives a complete failure report.
6. Request required human approval before overwrite or high-risk finalization.

## Missing Baseline Flow

1. If no baseline exists, mark `diff.available` as `false`.
2. Continue with validation and scoring.
3. Record the missing baseline in warnings and final artifact output.
