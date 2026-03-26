# Scrapy Settings Reference

Complete settings catalog for `@jadecli/scrapy-cli` generated spiders.

## Core Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `BOT_NAME` | project name | Identifies the crawler in logs and User-Agent |
| `SPIDER_MODULES` | `[project.spiders]` | Where Scrapy looks for spider classes |
| `ROBOTSTXT_OBEY` | `True` | Always respect robots.txt |
| `USER_AGENT` | jadecli-* | Identifies requests. Be honest about what you are. |

## Rate Limiting

| Setting | Default | Description |
|---------|---------|-------------|
| `DOWNLOAD_DELAY` | 1.0 | Seconds between requests to same domain |
| `CONCURRENT_REQUESTS` | 8 | Max parallel requests globally |
| `CONCURRENT_REQUESTS_PER_DOMAIN` | 4 | Max parallel per single domain |
| `CONCURRENT_REQUESTS_PER_IP` | 0 | Per-IP limit (0 = disabled, use domain) |
| `RANDOMIZE_DOWNLOAD_DELAY` | True | Randomize 0.5x–1.5x of DOWNLOAD_DELAY |

## AutoThrottle

Adjusts delay based on server response latency. Prefer this over static delays.

| Setting | Default | Description |
|---------|---------|-------------|
| `AUTOTHROTTLE_ENABLED` | True | Enable adaptive throttling |
| `AUTOTHROTTLE_START_DELAY` | 1 | Initial delay before measuring |
| `AUTOTHROTTLE_TARGET_CONCURRENCY` | 2.0 | Target parallel requests per server |
| `AUTOTHROTTLE_MAX_DELAY` | 30 | Upper bound on calculated delay |
| `AUTOTHROTTLE_DEBUG` | False | Log throttle decisions (noisy) |

## Retry

| Setting | Default | Description |
|---------|---------|-------------|
| `RETRY_ENABLED` | True | Retry failed requests |
| `RETRY_TIMES` | 3 | Max retries per request |
| `RETRY_HTTP_CODES` | `[500,502,503,504,522,524,408,429]` | HTTP codes that trigger retry |

## Output

| Setting | Default | Description |
|---------|---------|-------------|
| `FEEDS` | `{}` | Dict of URI → format config |
| `FEED_EXPORT_ENCODING` | `utf-8` | Always UTF-8 |
| `FEED_EXPORT_INDENT` | `None` | Pretty-print JSON (set to 2 for debug) |

## Depth & Limits

| Setting | Default | Description |
|---------|---------|-------------|
| `DEPTH_LIMIT` | 0 | Max crawl depth (0 = unlimited) |
| `CLOSESPIDER_ITEMCOUNT` | 0 | Stop after N items (0 = unlimited) |
| `CLOSESPIDER_TIMEOUT` | 0 | Stop after N seconds (0 = unlimited) |
| `DOWNLOAD_TIMEOUT` | 30 | Request timeout in seconds |

## Middleware Stack (order matters)

| Middleware | Priority | Description |
|-----------|----------|-------------|
| `HttpAuthMiddleware` | 300 | HTTP Basic auth |
| `DownloadTimeoutMiddleware` | 350 | Applies DOWNLOAD_TIMEOUT |
| `DefaultHeadersMiddleware` | 400 | Sets default headers |
| `UserAgentMiddleware` | 500 | Sets User-Agent |
| `RetryMiddleware` | 550 | Retries failed requests |
| `HttpCompressionMiddleware` | 590 | Handles gzip/deflate |
| `RedirectMiddleware` | 600 | Follows redirects |
| `CookiesMiddleware` | 700 | Cookie jar management |
| `HttpProxyMiddleware` | 750 | Proxy support |
| `ScrapyPlaywrightMiddleware` | 1000 | JS rendering (if using playwright) |

## Pipeline Priorities

Lower number = runs first. Standard range: 100–1000.

```python
ITEM_PIPELINES = {
    "myproject.pipelines.ValidatePipeline": 100,   # Validate/clean
    "myproject.pipelines.DedupPipeline": 200,      # Deduplicate
    "crawler.pipelines.IndexPipeline": 300,        # Update index
    "crawler.pipelines.DiffPipeline": 400,         # Detect changes
    "crawler.pipelines.ChangelogPipeline": 500,    # Log changes
}
```

## Logging

| Setting | Default | Description |
|---------|---------|-------------|
| `LOG_LEVEL` | `INFO` | DEBUG/INFO/WARNING/ERROR/CRITICAL |
| `LOG_FORMAT` | `%(asctime)s...` | Python logging format string |
| `LOG_FILE` | None | Optional file output |
| `LOG_STDOUT` | False | Send logs to stdout (disable for cron) |

## Playwright Integration

When using scrapy-playwright for JS-heavy sites:

```python
custom_settings = {
    "DOWNLOAD_HANDLERS": {
        "https": "scrapy_playwright.handler.ScrapyPlaywrightDownloadHandler",
    },
    "PLAYWRIGHT_BROWSER_TYPE": "chromium",
    "PLAYWRIGHT_LAUNCH_OPTIONS": {"headless": True},
}
```

Request with: `yield scrapy.Request(url, meta={"playwright": True})`
