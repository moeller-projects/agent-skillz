# CI Entrypoint

CI must call only `scripts/ci-gate.sh`.

Do not orchestrate validation, scoring, diff, or artifact emission independently in CI.
