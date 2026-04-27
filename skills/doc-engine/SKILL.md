---
name: doc-engine
description: Use when writing or improving README files, AGENTS.md guidance, architecture notes, or workflow documentation. Avoid when only implementation is requested.
title: Doc Engine
version: 0.2.0
summary: Create accurate technical docs, READMEs, AGENTS.md files, and developer guides with clear structure.
---

# Doc Engine

## Purpose

Create and improve technical documentation, README files, AGENTS.md files, architecture notes, diagrams, and usage docs that help people act correctly.

## Use When

- Writing or improving a README.
- Writing or refining AGENTS.md guidance.
- Documenting architecture or developer workflows.
- Creating usage docs or technical notes.
- Explaining how a system should be used or maintained.

## Avoid When

- The user wants implementation only.
- Documentation would duplicate obvious code.

## Workflow

1. Identify the audience, task, and missing decisions the doc must support; if audience is unclear, state the assumption explicitly.
2. Build a clear structure before expanding prose.
3. Keep commands, file paths, and workflow steps accurate; verify each before including.
4. Add only the context needed to make the reader effective.
5. Note remaining gaps, assumptions, or follow-up docs.

## Output Contract

Default:

```text
doc:
- purpose:
- audience:
- structure:

changes:
- ...

gaps:
- ...
```

## Error Handling

1. Local: If audience or purpose is unclear, ask one question before drafting.
2. Flow: Skip sections where source material is missing; note each gap explicitly.
3. Recovery: Preserve original text by presenting changes as a diff, not a full replacement.

## Validation Checklist

- [ ] Purpose and audience stated before any prose.
- [ ] Document structure defined before expanding sections.
- [ ] Every command, path, and step verified accurate.
- [ ] All gaps listed explicitly; none silently omitted.
- [ ] Changes presented as diffs, not full replacements, for existing docs.

See `tests/validation-checklist.md` for the full checklist.

## Assets

- `assets/templates/output.md` — concrete output template
- `assets/examples/happy-path.md` — new README creation scenario
- `assets/examples/edge-case.md` — missing source material scenario

## References

- See `references/workflow.md` for the detailed workflow.
- See `references/examples.md` for sample documentation outputs.

## Rules

- `rules/_sections.md`
- `rules/audience-first.md`
- `rules/command-accuracy.md`
- `rules/structure-over-prose.md`
- `rules/agentsmd-specificity.md`
- `rules/readme-completeness.md`
