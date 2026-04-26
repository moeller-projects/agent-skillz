# Rule: Early Return

> Impact: medium

## Description

Return as soon as a condition is met rather than nesting further.
Keeps code shallow and readable.

## Examples

### Good

```ts
if (!user) return null
return processUser(user)
```

### Bad

```ts
if (user) {
  return processUser(user)
} else {
  return null
}
```
