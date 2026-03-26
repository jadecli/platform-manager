# Crawler Context

Version-controlled decisions, strategies, and known issues per crawler source.
Each source gets its own XML file tracking:

- **Sources**: where we crawl, what we expect
- **Rate limits**: known limits, our strategy, why
- **Processing**: how we handle the data
- **Known issues**: documented over time from log review
- **Decisions**: numbered, dated, with rationale

## Checklist: New Crawler

Before creating or updating any crawler, complete this checklist:

1. [ ] **Research existing tools** — check if a plugin, SDK, or MCP already exists
   - Search Claude plugins: `claude plugin marketplace list` then search each
   - Search npm: `npm search <service>`
   - Search GitHub: `gh search repos "<service> claude plugin"`
   - Check if the service has an official API or SDK
2. [ ] **Fetch and inspect llms.txt** — understand page count, sections, URL patterns
3. [ ] **Check robots.txt** — verify crawl is permitted, note rate limits
4. [ ] **Review rate limit docs** — find official rate limit guidance
5. [ ] **Create directive JSON** — define spider using @jadecli/scrapy-cli schema
6. [ ] **Validate directive** — `scrapy-cli validate directive.json`
7. [ ] **Sample crawl** — `python -m crawler.tests.sample_crawl <spider> --pages 5`
8. [ ] **Review random output** — verify schema, content quality, no empty fields
9. [ ] **Document context** — create/update `crawler/context/<source>.xml`
10. [ ] **Full crawl** — only after sample passes and context is documented
11. [ ] **Review telemetry** — check crawl-stats.jsonl for errors, timing, rate behavior
12. [ ] **Commit** — directive, spider, context, test results
