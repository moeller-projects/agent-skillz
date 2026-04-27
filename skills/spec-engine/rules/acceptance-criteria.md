# Rule: Acceptance Criteria

> Impact: high

## Description

Write acceptance criteria that prove whether each requirement is complete.

## Apply When

- A requirement needs validation or sign-off conditions.

## Checks

- Acceptance item does not map to a requirement -> flag.
- Acceptance item restates the requirement without a verifiable outcome -> rewrite.
- Negative path or edge condition exists but no acceptance item covers it -> flag.

## Anti-Pattern

Using acceptance criteria as decorative restatements instead of testable completion gates.
