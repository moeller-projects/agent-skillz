# Rule: Flaky Test Reduction

> Impact: high

## Description

Treat flakiness as a diagnosable source of non-determinism, not a retry quota problem.

## Apply When

- Existing tests are unreliable or hard to trust.

## Checks

- Retry suggested before the flake source is identified -> flag.
- Non-deterministic fixture, cleanup, clock, or network dependency is unaddressed -> flag.
- `risk` omits confidence impact from known flakiness -> add it.

## Anti-Pattern

Masking flaky behavior with retries while leaving the root cause untouched.
