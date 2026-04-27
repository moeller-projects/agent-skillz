# Rule: Diff and Versioning

> Impact: medium

## Description

Make material requirement changes visible and reflect their impact on versioning or approval.

## Apply When

- Existing specs are being revised or compared.

## Checks

- Scope or contract change is not called out -> flag.
- Version or change note does not match the significance of the diff -> flag.
- Removed requirement or acceptance item disappears with no recorded rationale -> flag.

## Anti-Pattern

Overwriting requirements in place and pretending nothing material changed.
