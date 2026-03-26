---
name: scrapy-sdk
description: >
  TypeScript-driven Scrapy spider creation and management. Use when building web scrapers,
  creating spiders, managing crawl rates, configuring pipelines, or working with the agentic
  crawler. Generates consistent Python spiders from typed JSON directives. Also use when
  the user mentions crawling, scraping, indexing documentation, or monitoring web pages.
---

# scrapy-sdk

Generate and manage Scrapy spiders using TypeScript-typed directives.
Instead of writing ad-hoc Python spiders, define a JSON directive → SDK generates consistent code.

## Architecture

```
SpiderDirective (JSON)
    → @jadecli/scrapy-cli validate (Zod validation)
    → @jadecli/scrapy-cli create   (generates Python spider)
    → scrapy crawl <name>          (runs the spider)
    → crawler/indexes/             (tracks changes via pipelines)
```

## When to Use This Skill

- User asks to crawl a website or monitor pages for changes
- User needs to create a new spider for documentation indexing
- User wants to manage rate limits or crawl schedules
- User mentions scraping, crawling, or web data extraction
- User wants to index local files or track doc changes

## Workflow: Create a New Spider

1. **Define the directive** — create a JSON file matching the SpiderDirective schema:

```json
{
  "name": "my-spider",
  "description": "What this spider does",
  "type": "crawl",
  "allowedDomains": ["example.com"],
  "startUrls": ["https://example.com"],
  "fields": [
    {"name": "title", "selector": {"type": "css", "query": "h1"}, "type": "str", "required": true},
    {"name": "content", "selector": {"type": "css", "query": "article"}, "type": "str"}
  ],
  "rateLimit": {"downloadDelay": 2, "concurrentRequests": 4, "autoThrottle": true},
  "output": {"format": "jsonl", "path": "output/%(name)s-%(time)s.jsonl"},
  "tags": ["docs"]
}
```

2. **Validate**: `npx tsx packages/scrapy-cli/src/cli.ts validate directive.json`
3. **Generate**: `npx tsx packages/scrapy-cli/src/cli.ts create directive.json`
4. **Run**: `npx tsx packages/scrapy-cli/src/cli.ts run my-spider`
5. **Check**: `npx tsx packages/scrapy-cli/src/cli.ts status`

## Spider Types

| Type | Base Class | Use When |
|------|-----------|----------|
| `crawl` | CrawlSpider | Following links across a site, matching URL patterns |
| `sitemap` | SitemapSpider | Site has sitemap.xml, you want structured discovery |
| `feed` | XMLFeedSpider | Parsing RSS/XML feeds |
| `api` | Spider | Paginated API endpoints (REST, JSON) |
| `local` | Spider | Indexing local filesystem (no HTTP) |

## Rate Limit Presets

Always set rate limits. Never crawl without them.

| Preset | Delay | Concurrent | AutoThrottle | Use For |
|--------|-------|-----------|-------------|---------|
| `polite` | 3s | 2 | yes (1.0) | Public sites, first-time crawls |
| `standard` | 1s | 8 | yes (2.0) | Known-friendly sites |
| `aggressive` | 0.25s | 32 | no | Your own infrastructure |
| `local` | 0s | 64 | no | Local file indexing |

## Scrapy Settings Reference

Read `references/scrapy-settings.md` for the complete settings catalog with
descriptions and recommended values for each spider type.

## Key Patterns from Vendored Context

The vendored repos at `vendor/scrapy/` and `vendor/scrapy-ecosystem/` contain:

- **scrapy-playwright**: Use when sites require JavaScript rendering. Add to middleware.
- **scrapy-redis**: Use for distributed crawling across multiple machines.
- **scrapy-splash**: Alternative JS rendering via Splash (lighter than Playwright).
- **crawlab/Gerapy/scrapydweb**: Crawl management UIs — reference for scheduling patterns.
- **feapder**: BatchSpider pattern — good reference for incremental crawling.

Read `vendor/scrapy-ecosystem/INDEX.md` for the full list.

## Agentic Crawler

The built-in crawler at `crawler/` uses this SDK's patterns:

- `crawler/spiders/claude_docs.py` — monitors code.claude.com/docs daily
- `crawler/spiders/local_files.py` — indexes ecosystem XML/MD files
- `crawler/pipelines/` — index, diff, changelog tracking
- `crawler/schedules/daily-docs.sh` — cron schedule for doc monitoring

Run: `python -m crawler.run docs|local|all|changes`

## Field Selectors

```json
{"type": "css",   "query": "h1.title",              "extract": "first"}
{"type": "css",   "query": "a.link",   "attr": "href", "extract": "all"}
{"type": "xpath", "query": "//meta[@name='date']/@content"}
{"type": "css",   "query": ".price",   "re": "\\d+\\.\\d+", "type": "float"}
```

## Logging Guidelines

Scrapy's logging is controlled per-spider via `custom_settings`:

```python
custom_settings = {
    "LOG_LEVEL": "INFO",           # DEBUG for development, INFO for production
    "LOG_FILE": "logs/spider.log", # Optional file output
    "LOG_FORMAT": "%(asctime)s [%(name)s] %(levelname)s: %(message)s",
}
```

Use `self.logger.info()` in spiders, never `print()`.
