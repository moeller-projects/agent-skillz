---
name: thinking-engine
description: Use when a problem is vague, a plan needs critique, or options must be compared before execution.
title: Thinking Engine
version: 0.1.0
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

1. Restate the problem, constraints, and success bar.
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

## Rules

- `rules/_sections.md`
- `rules/assumption-audit.md`
- `rules/option-generation.md`
- `rules/decision-readiness.md`
