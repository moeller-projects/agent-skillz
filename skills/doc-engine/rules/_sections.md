# Rule: Standard Sections

> Impact: medium

## Description

Keep documentation planning deterministic so structure and content stay actionable.

## Apply When

- Planning or reviewing documentation output.

## Checks

- `target`, `structure`, `content`, `changes`, or `gaps` missing -> flag.
- `content` appears before `structure` -> reorder.
- Long prose paragraph replaces bullets -> rewrite.
- `gaps` omitted even though information is missing -> flag.

## Anti-Pattern

Writing a wall of prose that hides audience, structure, and remaining gaps.
