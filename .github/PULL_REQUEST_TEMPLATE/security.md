## Summary
<!-- What vulnerability was addressed -->

## Vulnerability
<!-- CVE/CWE if applicable, attack vector, severity -->

## Mitigation
```
Before (vulnerable):    After (secure):
user input ──→ eval()   user input ──→ validate ──→ safe_fn()
```

## Checklist
- [ ] No `pickle.loads()` on untrusted data
- [ ] SQL uses parameterized queries (`%s`), not f-strings
- [ ] URL inputs validated against allowlist
- [ ] No hardcoded credentials or tokens
- [ ] `ROBOTSTXT_OBEY = True` not overridden (if crawler)
- [ ] SECURITY.md updated (if new finding)
