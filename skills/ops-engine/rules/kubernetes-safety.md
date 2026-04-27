# Rule: Kubernetes Safety

> Impact: high

## Description

Keep Kubernetes changes explicit about privilege, resources, probes, and runtime assumptions.

## Apply When

- The task includes Kubernetes manifests, clusters, or workload design.

## Checks

- Resource limits, probes, or security context are omitted for a workload change -> flag.
- Networking, storage, or secret assumptions are implied instead of named -> flag.
- Cluster-level permission increase lacks justification in `security` -> flag.

## Anti-Pattern

Shipping cluster changes that ignore permissions, health checks, or resource boundaries.
