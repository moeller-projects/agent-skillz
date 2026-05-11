# agent-skillz [![skills.sh](https://skills.sh/b/anthropics/skills)](https://skills.sh/moeller-projects/agent-skillz)

Reusable AI coding agent skills with minimal Bun + TypeScript tooling for validation, build output, and consistent packaging.

## Quick start

```bash
bun install
bun run dev
```

## Skills

- `ado-gateway` — Azure DevOps work item and PR comment retrieval with normalized handoff output
- `caveman` — ultra-concise response protocol
- `thinking-engine` — exploration, assumptions, options, decision readiness
- `code-quality-engine` — clean code, refactoring, performance, modernization
- `test-engine` — unit, integration, E2E, coverage, flaky test reduction
- `repo-engine` — repo onboarding, architecture mapping, conventions, hotspots
- `spec-engine` — requirements, specs, acceptance criteria, policy gates
- `delivery-engine` — atomic task breakdown, dependencies, critical path, definitions of done
- `doc-engine` — README, AGENTS.md, developer docs, architecture docs
- `ops-engine` — CI/CD, Kubernetes, threat modeling, resilience, rollback

## Repository layout

- `skills/` — source skills
- `schemas/` — JSON schemas for skill documents
- `templates/` — starter templates
- `packages/skill-build/` — validation, build, and pack scripts
