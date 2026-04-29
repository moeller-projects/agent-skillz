# OpenSpec Gateway

Version: 0.1.0

Consume normalized requirement input, generate OpenSpec files, and enforce deterministic validation, scoring, diff, and version gates.

## Includes

- OpenSpec generation from normalized handoff input
- structure, style, and security validation gates
- scoring, diff, and version governance helpers
- CI entrypoint through `scripts/ci-gate.sh`

## Quick start

```bash
RISK_TIER=Medium ./scripts/spec-from-handoff.sh assets/examples/input-handoff.json /tmp/checkout-supports-discount-codes.md
```

```bash
./scripts/ci-gate.sh /tmp/checkout-supports-discount-codes.md
```

See `references/end-to-end.md` for the full bash-only flow from ADO handoff to final governance artifact.
