# Rule: Architecture Map

> Impact: high

## Description

Summarize the repository as domains, layers, and execution relationships instead of a flat tree.

## Apply When

- The task requires repository orientation or system understanding.

## Checks

- Major package or domain has no role description -> flag.
- `map` lists paths only, with no system meaning -> rewrite.
- `flow` omits how build, request, or data movement crosses boundaries -> flag.

## Anti-Pattern

Treating folder names alone as architecture.
