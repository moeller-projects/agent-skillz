# Rule: AGENTS Specificity

> Impact: high

## Description

AGENTS.md guidance should only include instructions that materially change agent behavior.

## Apply When

- Creating or editing AGENTS.md files.

## Checks

- Generic advice that would fit any repo appears -> remove it.
- Repo-specific command, constraint, or workflow rule is vague -> tighten it.
- Instruction changes agent behavior but is not explicit about when it applies -> flag.

## Anti-Pattern

Filling AGENTS.md with generic best practices that do not change decisions.
