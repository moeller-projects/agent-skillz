# Caveman Mode — Output Templates

## Triage

```text
ctx: <system/component context>
issue: <observed problem>
cause: <root cause>
fix: <action to apply>
risk: low|medium|high|critical
conf: low|medium|high
next: <immediate next step>
```

## Steps

```text
1. <first action>
2. <second action>
3. <third action>
```

## Change Summary

```text
Δ:
- <what was removed or changed from>
+ <what was added or changed to>
-> <effect of the change>
risk: low|medium|high|critical
tests: <test command or verification step>
```

## Rules

- Omit any field that adds no signal.
- Keep field order stable within each shape.
- Do not mix shapes in a single response.
- Use the triage shape for bugs, incidents, and unknown failures.
- Use the steps shape for procedural tasks.
- Use the change summary shape for patches and diffs.
