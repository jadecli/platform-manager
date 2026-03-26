## Summary
<!-- 1-3 bullets: what changed and why -->

## What changed
<!--
  For features: include ASCII wireframe/diagram showing before→after.
  For fixes: describe root cause → fix.
  For security: describe vulnerability → mitigation.
  Delete sections that don't apply.
-->

```
Before:              After:
┌──────────┐         ┌──────────┐
│          │   →     │          │
└──────────┘         └──────────┘
```

## Test plan
- [ ] Verified locally on macOS
- [ ] `npx tsc --noEmit` passes (if TS changed)

## Checklist
- [ ] Single logical change
- [ ] No hardcoded credentials
- [ ] No `ANTHROPIC_API_KEY` (use OAuth)
