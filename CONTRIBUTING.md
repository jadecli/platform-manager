# Contributing to platform-manager

## PR Scoping (Cherny Method)

Every PR follows Boris Cherny's type-first, behavior-verified approach:

### Before Writing Code

1. **Define the types first.** What interfaces, schemas, or Zod types change? Write them before implementation. Types are the contract — implementation follows.

2. **Enumerate exhaustive cases.** Use `match` in Python, `switch` with exhaustive checks in TypeScript. If you add a new spider type, every switch on `SpiderType` must handle it.

3. **Scope to one logical change.** A PR does ONE thing:
   - Add a spider (spider + directive + context + test)
   - Fix a bug (fix + test proving the fix)
   - Refactor (same behavior, different structure)
   - Never bundle unrelated changes.

4. **Write tests that verify behavior, not implementation.** Test "does the spider produce items with correct fields?" not "does the spider call response.css exactly 3 times?"

### PR Sizing Guide

| Size | Files | Description |
|------|-------|-------------|
| XS | 1-2 | Config change, typo fix, single-field addition |
| S | 3-5 | New spider + directive + context + test |
| M | 6-10 | New SDK primitive + generator changes + tests |
| L | 11-20 | New pipeline with schema migration + tests |
| XL | 20+ | Split into smaller PRs. If you can't, explain why. |

### PR Title Convention

```
<type>(<scope>): <subject>

feat(crawler): add netlify_docs spider
fix(cache): handle 304 responses with empty body
security(neon): parameterize all SQL in cache storage
crawl(neon-docs): update rate limit after 429 detection
docs(context): add netlify-docs.xml crawler context
```

### A/B Testing for Uncertain Implementations

When unsure between approaches:

1. Create branch `feat/approach-a` and `feat/approach-b`
2. Run sample crawls on both: `npm run crawl:test -- <spider> --pages 10`
3. Compare metrics in crawl-stats.jsonl:
   - Items scraped per second
   - Cache hit rate
   - Error count
   - Content quality (manual review of 3 random samples)
4. Document winner and reasoning in PR description
5. Merge winner, close loser with comparison notes

## Conventional Commits

All commits must follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat:     New feature
fix:      Bug fix
security: Security fix or audit
crawl:    Crawler-specific changes
perf:     Performance improvement
refactor: Code restructuring
docs:     Documentation
test:     Tests
build:    Build/dependency changes
ci:       CI/CD
chore:    Maintenance
```

Enforced by commitlint via husky pre-commit hook.

## Release Process

```bash
npm run release          # auto-bump based on commits
npm run release:minor    # force minor bump
npm run release:major    # force major bump
```

Generates CHANGELOG.md from conventional commits.

## Security

Every PR touching crawler code must complete the Security Checklist in the PR template. See `.github/pull_request_template.md`.

For new spiders, also complete the New Crawler Checklist in `crawler/context/README.md`.
