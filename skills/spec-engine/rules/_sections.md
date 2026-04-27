# Rule: Standard Sections

> Impact: medium

## Description

Keep specification output deterministic so approved facts, gates, and open questions stay separate.

## Apply When

- Drafting or validating a specification.

## Checks

- `goal`, `scope`, `requirements`, `acceptance`, `gates`, or `open` missing -> flag.
- Requirement lines not numbered as `FR-n` -> flag.
- Acceptance lines not numbered as `AC-n` -> flag.
- Confirmed requirements mixed into `open` or unresolved items mixed into `requirements` -> flag.

## Anti-Pattern

Mixing approved scope, tentative ideas, and governance status into one blob.
