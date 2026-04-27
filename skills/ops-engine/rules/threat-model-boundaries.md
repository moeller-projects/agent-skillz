# Rule: Threat Model Boundaries

> Impact: high

## Description

Ground security review in explicit assets, actors, trust boundaries, and abuse cases.

## Apply When

- Security risk, exposure, or threat modeling is part of the task.

## Checks

- Asset, actor, or trust boundary is unnamed -> flag.
- Mitigation is listed without a concrete threat or abuse case -> flag.
- Security-sensitive change has no corresponding `security` entry -> block completion.

## Anti-Pattern

Listing generic security advice without tying it to the real system boundary.
