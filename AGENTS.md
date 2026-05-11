# AGENTS.md

This repo contains reusable agent skills.

## Rules

- Skills live in `skills/{skill-name}/`
- Use kebab-case for names
- Every skill must contain:
  - `SKILL.md`
  - `README.md`
  - `metadata.json`
- Versions must match between files
- Keep `SKILL.md` concise
- Do not manually edit generated files
- Make minimal changes

## Commands

```bash
bun install
bun run dev
```

## Skill Architect Agent

For creating, auditing, or refactoring skills, use the dedicated agent:

`.github/agents/skill-architect.agent.md`

Activate it when the task involves writing a new skill, reviewing an existing
skill's quality, or making structural changes to skill files.

## Build Pipeline

The build pipeline lives in `packages/skill-build/`. It runs three stages:

- `bun run validate` — validates all skills (required files, metadata, frontmatter)
- `bun run build` — generates `skills/INDEX.md` (do not edit manually)
- `bun run pack` — produces zip artifacts in `artifacts/skills/`

Run `bun run dev` to execute all three in sequence.

`skills/INDEX.md` is a generated file. Never edit it manually.

## Schemas and Templates

`schemas/metadata.schema.json` — JSON Schema for `metadata.json` files.
Used for IDE autocomplete and external tooling. Runtime validation is
performed by `packages/skill-build/src/validate.ts`.

`templates/` — Starter scaffolds for new skills. Four types are available:
`prompt-skill`, `rule-skill`, `script-skill`, `hybrid-skill`. Copy the
relevant template directory into `skills/` and replace `{{...}}` placeholders.
