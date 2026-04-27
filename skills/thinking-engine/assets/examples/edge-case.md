# Edge-Case Example — Thinking Engine: Only One Viable Option

## Scenario

Lead asks: "Should we use our existing Postgres DB for the job queue, or add Redis?"

## Why This Is an Edge Case

After assumption audit, only one option is genuinely viable given the constraints.
The skill must state this explicitly rather than manufacturing false alternatives.

## Input Context

- Team: 1 engineer.
- Timeline: must ship in 3 days.
- Infra budget: $0 additional (no new services this quarter).
- Current stack: Postgres already in use; no Redis instance.

## Expected Output

```text
problem:
- restatement: choose a job queue implementation that ships in 3 days with no new infra spend
- constraints: 1 engineer, 3-day deadline, $0 infra budget, no Redis instance
- success-bar: jobs enqueue and process reliably without dropping work on restart

assumptions:
- job volume is low-to-medium (< 1000 jobs/day) — risk: high if volume spikes; revalidate
- Postgres transactional guarantees are sufficient for at-least-once delivery — risk: low
- no Redis means provisioning Redis is not an option this sprint — risk: low (budget constraint confirmed)

only-option: Postgres-backed queue (e.g., pg-boss or custom advisory lock table)
reason: Redis is unavailable within budget; external queue services (SQS, etc.) require new
  infra spend; Postgres queue is achievable in 3 days with at-least-once semantics and
  no new operational surface area

alternatives-ruled-out:
- Redis + BullMQ: requires provisioning Redis — budget constraint eliminates this
- SQS or cloud queue: new infra spend — budget constraint eliminates this
- In-memory queue: lost on restart — violates success bar

blind-spots:
- Postgres job queue adds load to the primary DB; monitor query performance
- At high volume (>10k jobs/day), revisit this decision

next:
- evaluate pg-boss vs custom advisory lock implementation (2 hours)
- open: what is the expected job volume per day? (determines whether Postgres queue
  is safe long-term or a 6-month bridge solution)
```

## Why This Is Correct

- Only one viable option given hard constraints.
- Alternatives ruled out are stated with explicit reasons, not silently dropped.
- Blind spots are called out.
- Open question surfaces the volume assumption that determines long-term viability.
