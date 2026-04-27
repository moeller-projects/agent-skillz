# Happy-Path Example — Caveman Mode

## Scenario

User asks: "Why is my API returning 500 on `/users/:id`? Using Express, Postgres."

## Input Context

- Route handler queries DB with `userId` from params.
- Error log shows: `invalid input syntax for type integer`.
- Param arrives as string, not cast.

## Expected Output (full level, triage shape)

```text
ctx: Express /users/:id handler
issue: 500 on valid request
cause: userId param is string; Postgres expects integer
fix: parseInt(req.params.id, 10) before query; validate NaN
risk: low
conf: high
next: redeploy, test with id=abc to confirm 400 guard
```

## Why This Is Correct

- Uses triage shape.
- All fields present because all are relevant.
- No filler or restatement.
- Fix is exact and executable.
- Risk and confidence are justified.
