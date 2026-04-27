---
name: repo-engine
description: Use when onboarding into a repository, mapping architecture, finding entry points, or extracting conventions and hotspots.
title: Repo Engine
version: 0.1.0
summary: Map repository architecture, entry points, conventions, hotspots, and onboarding artifacts for fast execution.
---

# Repo Engine

## Purpose

Scan repositories, infer architecture, detect entry points, extract conventions, identify hotspots, and produce onboarding artifacts that accelerate future work.

## Use When

- Onboarding into a repository or monorepo.
- Understanding architecture before making changes.
- Mapping entry points and execution flows.
- Extracting conventions and development hotspots.
- Producing agent-ready onboarding artifacts.

## Avoid When

- The user already provided exact files for a small patch.
- Only code quality review is needed.

## Workflow

1. Scan the repo layout, build system, and major domains.
2. Identify entry points, ownership seams, and runtime paths.
3. Extract conventions, workflows, and recurring patterns.
4. Highlight hotspots, risks, and likely change surfaces.
5. Package the findings into reusable onboarding artifacts.

## Output Contract

Default:

```text
repo_map:
- ...

entrypoints:
- ...

conventions:
- ...

hotspots:
- ...

agent_artifacts:
- ...
```

## Rules

- `rules/_sections.md`
- `rules/architecture-map.md`
- `rules/entrypoint-detection.md`
- `rules/convention-extraction.md`
- `rules/hotspot-identification.md`
