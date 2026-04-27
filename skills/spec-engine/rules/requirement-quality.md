# Rule: Requirement Quality

> Impact: critical

## Description

Make each requirement explicit, scoped, and testable.

## Apply When

- Turning user intent into formal requirements.

## Checks

- Requirement uses vague words like better, easier, seamless, or intuitive -> rewrite.
- Actor, trigger, or observable outcome is missing -> flag.
- Hidden dependency or out-of-scope behavior is embedded in one requirement -> split it.

## Anti-Pattern

Shipping a requirement list that sounds good but cannot be built or verified consistently.
