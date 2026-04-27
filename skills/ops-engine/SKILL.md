---
name: ops-engine
description: Use when designing CI/CD, reviewing infrastructure, working with containers or Kubernetes, or analyzing deployment and security risk.
title: Ops Engine
version: 0.1.0
summary: Plan safer delivery across CI/CD, containers, Kubernetes, reliability, threat modeling, and rollback decisions.
---

# Ops Engine

## Purpose

Handle DevOps, CI/CD, containers, Kubernetes, reliability, threat modeling, deployment safety, and operational risk with explicit safeguards.

## Use When

- Creating or reviewing CI/CD workflows.
- Working with Docker, containers, or Kubernetes.
- Threat modeling a service or deployment path.
- Designing resilience, rollback, or release safety plans.
- Analyzing operational or deployment risk.

## Avoid When

- The task is pure application refactoring.
- The task is pure documentation.

## Workflow

1. Define the system boundary, change surface, and operational risk.
2. Identify delivery, security, and runtime failure modes.
3. Design the safest plan for build, release, runtime, and rollback.
4. Verify reproducibility, least privilege, and observability needs.
5. Deliver the plan with checks, rollback, and security notes.

## Output Contract

Default:

```text
risk:
- ...

plan:
1. ...

checks:
- ...

rollback:
- ...

security:
- ...
```

## Rules

- `rules/_sections.md`
- `rules/deployment-safety.md`
- `rules/ci-cd-reproducibility.md`
- `rules/kubernetes-safety.md`
- `rules/threat-model-boundaries.md`
- `rules/resilience-rollback.md`
