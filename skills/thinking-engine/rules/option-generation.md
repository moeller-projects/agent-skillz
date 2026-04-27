# Rule: Option Generation

> Impact: high

## Description

Generate only materially different options so tradeoffs are real and decision-ready.

## Apply When

- Multiple implementation or strategy paths are possible.

## Checks

- Fewer than 2 options when real tradeoffs exist -> flag.
- More than 5 options -> trim to the strongest set.
- Superficial variations of the same approach presented as different options -> merge or remove.

## Anti-Pattern

Listing shallow variants of one idea and pretending the user received a real choice set.
