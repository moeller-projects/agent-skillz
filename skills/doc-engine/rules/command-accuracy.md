# Rule: Command Accuracy

> Impact: high

## Description

Commands, paths, flags, and workflow steps must match reality.

## Apply When

- The document contains runnable commands or file references.

## Checks

- Command is unverified against the current repo or toolchain -> flag.
- Path or filename does not match the repository -> flag.
- Step order would fail if followed literally -> rewrite.

## Anti-Pattern

Copying stale commands or guessed paths into docs without verification.
