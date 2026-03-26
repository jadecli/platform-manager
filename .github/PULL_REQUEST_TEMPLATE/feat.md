## Summary
<!-- What feature was added and why -->

## What changed

### Architecture
<!-- ASCII diagram showing how this fits into the system -->
```
┌─────────┐     ┌─────────┐     ┌─────────┐
│ input   │ ──→ │ new     │ ──→ │ output  │
│         │     │ feature │     │         │
└─────────┘     └─────────┘     └─────────┘
```

### Files
<!-- Key files added/modified — helps reviewers navigate -->

### Docs updated
- [ ] README or INTEGRATIONS.md updated (if user-facing)
- [ ] CLAUDE.md or SKILL.md updated (if agent-facing)

## Test plan
- [ ] Verified locally on macOS
- [ ] `npx tsc --noEmit` passes (if TS changed)

## Checklist
- [ ] Single logical change
- [ ] Types defined before implementation
- [ ] No hardcoded credentials or `ANTHROPIC_API_KEY`
- [ ] ASCII diagram included for architecture changes
