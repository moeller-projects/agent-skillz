# agent-skillz

Reusable AI coding agent skills with minimal Bun + TypeScript tooling for validation, build output, and consistent packaging.

## Quick start

```bash
bun install
bun run dev
```

## Skills

- `caveman` — ultra-concise response protocol
- `thinking-engine` — deterministic problem framing, options, decision, risks, next steps
- `code-quality-engine` — deterministic findings, fix planning, risk, and validation output
- `test-engine` — deterministic test target, cases, gaps, and risk planning
- `repo-engine` — deterministic repo map, entry flow, conventions, hotspots, and next actions
- `spec-engine` — deterministic numbered requirements, acceptance criteria, gates, and open items
- `doc-engine` — deterministic documentation target, structure, content, changes, and gaps
- `ops-engine` — deterministic operational risk, rollout, checks, rollback, and security planning

## Repository layout

- `skills/` — source skills
- `schemas/` — JSON schemas for skill documents
- `templates/` — starter templates
- `packages/skill-build/` — validation, build, and pack scripts
