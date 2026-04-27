# Rule: CI/CD Reproducibility

> Impact: high

## Description

Make build and delivery workflows repeatable across reruns and environments.

## Apply When

- Creating or reviewing CI/CD pipelines.

## Checks

- Mutable dependency, floating version, or hidden environment assumption exists -> flag.
- Same revision cannot be rebuilt with the documented inputs -> flag.
- `checks` omits verification of reproducible build or artifact provenance -> add it.

## Anti-Pattern

Allowing pipelines to depend on mutable state or hidden local setup.
