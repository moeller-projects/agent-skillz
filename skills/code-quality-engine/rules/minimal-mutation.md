# Rule: Minimal Mutation

> Impact: high

## Description

Prefer the smallest safe change set that resolves the material issue.

## Apply When

- The code is fragile, legacy, or lightly tested.

## Checks

- Proposed change touches unrelated areas -> flag.
- Rewrite is suggested without proving the narrow fix is unsafe -> flag.
- `plan` step cannot be tied to a named finding -> remove it.

## Anti-Pattern

Using a quality pass to justify a broad rewrite with avoidable risk.
