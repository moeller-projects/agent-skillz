# Rule: Deployment Safety

> Impact: critical

## Description

Prioritize safe rollout, blast-radius control, health verification, and operator visibility before endorsing a deployment path.

## Apply When

- A release, migration, or infrastructure change is involved.

## Checks

- The plan includes staging, gating, or progressive rollout where appropriate.
- Health checks and failure signals are defined.

## Anti-Pattern

Treating deployment as a single irreversible step with no guardrails.
