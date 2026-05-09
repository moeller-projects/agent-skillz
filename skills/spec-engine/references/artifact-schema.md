# Artifact Schema

<!--
risk_tier values:
  Low      — cosmetic or internal-only clarification
  Medium   — additive feature or requirement change
  High     — cross-module behavior change
  Critical — public behavior, API, or security posture change
-->

```json
{
  "spec": {
    "goal": "string",
    "scope": ["string"],
    "requirements": [
      { "id": "string", "statement": "string" }
    ],
    "acceptance_criteria": [
      { "requirement_id": "string", "criteria": ["string"] }
    ]
  },
  "risk_tier": "Low | Medium | High | Critical",
  "quality_gates": ["string"],
  "open_questions": ["string"]
}
```
