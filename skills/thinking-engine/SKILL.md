---
name: thinking-engine
description: Use when the problem is vague, assumptions need pressure-testing, or options must be compared before commitment. Do not use when scope is fixed and the output must be an executable task breakdown with dependencies and done criteria.
allowed-tools: []
title: Thinking Engine
version: 0.2.0
summary: Explore ambiguous problems, test assumptions, compare options, and produce decision-ready plans.
---

# Thinking Engine

## Purpose

Explore unclear problems, challenge assumptions, surface blind spots, generate options, and turn ambiguity into a decision-ready plan.

## Use When

- The problem is vague or underspecified.
- The user asks what they may be missing.
- Options are needed before implementation.
- A plan needs critique before commitment.
- MVP scope needs validation before execution.

## Avoid When

- Implementation is already decided.
- The user wants direct execution only.
- A concise answer matters more than exploration.

## Workflow

1. Restate the problem, constraints, and success bar; if the problem remains vague after restatement, ask one clarifying question.
2. Audit assumptions, risks, unknowns, and hidden dependencies.
3. Generate a small set of materially different options.
4. Compare tradeoffs, pressure-test MVP scope, and note blind spots.
5. Recommend a path with explicit next steps and open questions.

## Output Contract

Default:

```text
problem:
- ...

assumptions:
- ...

options:
1. ...

recommendation:
- ...

next:
- ...
```

## Error Handling

1. Local: If the problem remains ambiguous after analysis, ask one targeted question before generating options.
2. Flow: Skip option comparison if only one viable path exists; state the reasoning explicitly.
3. Recovery: Return to the problem restatement step if new information invalidates prior assumptions.

## Validation Checklist

- [ ] Problem restated with constraints and success bar.
- [ ] Assumptions audited before options are generated.
- [ ] At least 2 materially different options (unless only 1 is viable; ruled-out list required).
- [ ] Recommendation includes blind spots.
- [ ] Open questions listed and gated.

See `tests/validation-checklist.md` for the full checklist.

## Assets

- `assets/templates/output.md` — concrete output template
- `assets/examples/happy-path.md` — real-time notifications design scenario
- `assets/examples/edge-case.md` — single viable option scenario
- `scripts/validate-output.sh` — validates output structure

## References

- See `references/workflow.md` for the detailed workflow.
- See `references/examples.md` for sample decision artifacts.

## Rules

- `rules/_sections.md`
- `rules/assumption-audit.md`
- `rules/option-generation.md`
- `rules/decision-readiness.md`
