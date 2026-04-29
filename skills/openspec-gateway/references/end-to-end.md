# End-to-End Bash Flow

```bash
RISK_TIER=Medium ./scripts/spec-from-handoff.sh ../ado-gateway/assets/examples/work-item-plus-pr-comments.json /tmp/checkout-supports-discount-codes.md
./scripts/ci-gate.sh /tmp/checkout-supports-discount-codes.md
```

This flow consumes the normalized handoff, generates a spec, and emits a governance artifact through the single CI entrypoint.
