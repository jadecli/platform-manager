## Summary

<!-- 1-3 sentences: what changed and why -->

## Session Context

<!-- Auto-injected by session-init hook. Fill manually if not available. -->

| Field | Value |
|-------|-------|
| Surface | <!-- e.g., Ghostty / iTerm2 / VS Code --> |
| Identity | <!-- e.g., jade@jadecli.com --> |
| Platform | <!-- cli / vscode --> |
| Claude CLI | <!-- version --> |
| Model | <!-- e.g., claude-opus-4-6 --> |

## Scope (Cherny Method)

<!--
  Each PR should be small and focused. Answer these before writing code:
  1. What types/interfaces change? (type-first design)
  2. What is the exhaustive set of cases? (pattern matching)
  3. What existing tests break? (behavior, not implementation)
-->

- [ ] Types defined before implementation
- [ ] Single logical change (not bundled)
- [ ] Tests verify behavior, not implementation details
- [ ] No unrelated refactoring included

## Crawl Details (if applicable)

<!-- Fill this section when the PR touches spiders, pipelines, or crawl config -->

| Setting | Value |
|---------|-------|
| Spider | <!-- e.g., claude_docs --> |
| Source | <!-- e.g., code.claude.com/docs --> |
| Rate Strategy | <!-- polite / standard / aggressive --> |
| Download Delay | <!-- e.g., 2s --> |
| Concurrent Reqs | <!-- e.g., 2 --> |
| AutoThrottle | <!-- on/off --> |
| Cache Policy | <!-- RFC2616 / DummyPolicy --> |
| Sample Test | <!-- pass/fail + item count --> |

## A/B Test (if uncertain about implementation)

<!--
  When unsure about an approach, run both and compare:
  - Branch A: <description>
  - Branch B: <description>
  - Metrics compared: <what you measured>
  - Winner: <which branch and why>
-->

## Log Capture Checklist

- [ ] `LOG_LEVEL` appropriate (INFO for production, DEBUG for investigation)
- [ ] No secrets in log output (DATABASE_URL, API keys, auth headers)
- [ ] Telemetry extension enabled (`TelemetryExtension` in EXTENSIONS)
- [ ] Claude usage tracked if agentic operation (`track_usage()` called)
- [ ] crawl-stats.jsonl reviewed after test run
- [ ] Sample crawl output reviewed for schema compliance

## Security Checklist

- [ ] No hardcoded credentials (use env vars / GitHub secrets)
- [ ] SQL queries use parameterized placeholders (`%s`), not f-strings
- [ ] `ROBOTSTXT_OBEY = True` not overridden
- [ ] `allowed_domains` set on all spiders (prevents SSRF)
- [ ] Vendored code has no `.git/` directories
- [ ] Output paths covered by `.gitignore`
- [ ] No `pickle.loads()` on untrusted data without validation

## Test Plan

- [ ] `scrapy-cli validate` passes on any new/modified directives
- [ ] `python -m crawler.tests.sample_crawl <spider> --pages 5` passes
- [ ] Random output samples reviewed (schema, content quality, no empty fields)
- [ ] Telemetry reviewed (crawl-stats.jsonl, no errors)
- [ ] TypeScript: `npx tsc --noEmit` passes (0 errors)
