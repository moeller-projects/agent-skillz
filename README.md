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

- `docs/` — portfolio review notes and other supporting documentation
- `skills/` — source skills
- `schemas/` — JSON schemas for skill documents
- `templates/` — starter templates
- `packages/skill-build/` — validation, build, and pack scripts

## Automated per-skill versioning

This repository uses per-skill semantic versioning via GitHub Actions.

- Pull requests that change `skills/<skill-name>/` must include `.changes/skills/<skill-name>.json`.
- The PR check workflow validates these intent files and bump types (`major`/`minor`/`patch`).
- On merge to `main`, release automation bumps that skill's version in:
  - `skills/<skill-name>/metadata.json`
  - `skills/<skill-name>/SKILL.md` frontmatter
  - `skills/<skill-name>/README.md` (`Version:` line)
- Release automation also updates `skills/<skill-name>/CHANGELOG.md`, regenerates `skills/INDEX.md`, creates per-skill tags, and uploads zip artifacts.

See `.changes/README.md` for the intent file format.
