# Rule: Policy Gates

> Impact: high

## Description

Identify the governance, compliance, safety, or approval gates that block implementation.

## Apply When

- The work is subject to process, policy, or risk review.

## Checks

- Required review or approval is implied instead of named in `gates` -> flag.
- Optional follow-up is mixed with a blocking gate -> split it.
- Policy-sensitive requirement has no owning gate or reviewer -> flag.

## Anti-Pattern

Treating governed work like an ordinary backlog item with no explicit gate.
