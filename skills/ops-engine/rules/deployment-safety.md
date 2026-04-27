# Rule: Deployment Safety

> Impact: critical

## Description

Prioritize rollout safety, blast-radius control, and health verification before approving a deployment path.

## Apply When

- A release, migration, or infrastructure change is involved.

## Checks

- No staged rollout, gate, or blast-radius control is described for a risky change -> flag.
- Health signal or failure trigger is missing from `checks` -> flag.
- Irreversible action appears before validation steps -> reorder.

## Anti-Pattern

Treating deployment as one irreversible step with no guardrails.
