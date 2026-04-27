# Rule: Entrypoint Detection

> Impact: high

## Description

Identify the real execution, build, and runtime entry points that control behavior.

## Apply When

- A repo map or onboarding artifact is being created.

## Checks

- Startup command, package entry, workflow trigger, or handler is missing from `entry` -> flag.
- Helper modules are presented as primary entry points -> fix classification.
- `flow` does not connect entry points to downstream execution -> flag.

## Anti-Pattern

Listing random source files without showing where execution actually starts.
