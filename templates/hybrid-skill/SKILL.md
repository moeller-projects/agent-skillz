---
name: {{skill-name}}
description: {{description}}
title: {{Skill Title}}
version: {{version}}
summary: {{summary}}
---

# {{Skill Title}}

## Purpose

{{One paragraph describing what this skill does and why it exists.}}

## Use When

- {{Specific trigger condition 1.}}
- {{Specific trigger condition 2.}}

## Avoid When

- {{Condition that would be a false positive.}}
- {{Related task that belongs to a different skill.}}

## Workflow

1. {{First step — confirm inputs and constraints.}}
2. {{Second step — primary action.}}
3. {{Third step — produce output.}}

## Output Contract

```text
{{output field 1}}: {{description}}
{{output field 2}}: {{description}}
```

## Error Handling

1. Local: {{What to do when a single step fails.}}
2. Flow: {{When to skip or abort.}}
3. Recovery: {{How to roll back or restore state.}}

## Validation Checklist

- [ ] {{Concrete output quality check 1.}}
- [ ] {{Concrete output quality check 2.}}

Create `tests/validation-checklist.md` with a full validation checklist after copying this template.

## Assets

- `assets/templates/output.md` — output template (create after copying template)
- `assets/examples/happy-path.md` — standard scenario (create after copying template)
- `assets/examples/edge-case.md` — failure or partial input scenario (create after copying template)

## References

- See `references/workflow.md` for the detailed workflow. (create after copying template)

## Rules

- `rules/_sections.md`
- `rules/{{rule-name}}.md`

## Scripts

- `scripts/{{script-name}}.sh` — {{what it does}}
