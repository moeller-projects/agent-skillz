# Edge-Case Example — Caveman Mode: Safety Override

## Scenario

User asks (in caveman mode): "Drop the `sessions` table — all sessions are stored in Redis now."

## Why This Is an Edge Case

Destructive, irreversible action. Safety override applies before caveman compression.

## Expected Output

```text
WARNING: destructive and irreversible.
- Verify: all session reads/writes point to Redis in prod.
- Backup: pg_dump sessions before dropping.
- Confirm: no active sessions rely on the table (check monitoring).

If confirmed:
DROP TABLE sessions;

risk: critical
next: run backup → verify Redis parity → execute drop → confirm 0 rows remain
```

## Why This Is Correct

- Leads with plain-language warning (safety override active).
- Provides exact backup and verification steps before the destructive command.
- Returns to caveman format after the warning with `risk:` and `next:`.
- Does not skip the warning even though user requested caveman mode.
