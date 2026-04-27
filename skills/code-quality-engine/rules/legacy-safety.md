# Rule: Legacy Safety

> Impact: high

## Description

Handle legacy code with incremental changes, compatibility awareness, and rollback-friendly sequencing.

## Apply When

- Touching old, under-tested, or business-critical code paths.

## Checks

- Hidden dependency or coupling risk omitted -> flag.
- Large modernization step proposed without intermediate validation -> split it.
- Migration has no residual risk note in `risk` -> add one.

## Anti-Pattern

Replacing legacy patterns wholesale without proving compatibility or a safe recovery path.
