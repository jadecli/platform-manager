"""Platform-manager crawler settings.

Two modes:
  - web: crawls code.claude.com/docs/llms.txt and linked pages for CLI doc changes
  - local: crawls local files to maintain a canonical documentation index

Scrapy-based with custom pipelines for index maintenance.
"""

BOT_NAME = "platform-crawler"
SPIDER_MODULES = ["crawler.spiders"]
NEWSPIDER_MODULE = "crawler.spiders"

# Crawl responsibly
ROBOTSTXT_OBEY = True
CONCURRENT_REQUESTS = 4
DOWNLOAD_DELAY = 1.0
COOKIES_ENABLED = False

# User agent
USER_AGENT = "jadecli-platform-crawler/0.1 (+https://github.com/jadecli/platform-manager)"

# Pipelines
ITEM_PIPELINES = {
    "crawler.pipelines.IndexPipeline": 300,
    "crawler.pipelines.DiffPipeline": 400,
    "crawler.pipelines.ChangelogPipeline": 500,
}

# Index storage
INDEX_DIR = "crawler/indexes"
CHANGELOG_PATH = "crawler/indexes/changelog.jsonl"

# Feed export
FEEDS = {
    "crawler/indexes/latest-crawl.json": {
        "format": "json",
        "overwrite": True,
    },
}

# Telemetry extension — writes crawl stats to crawler/telemetry/crawl-stats.jsonl
EXTENSIONS = {
    "crawler.telemetry.stats_collector.TelemetryExtension": 500,
}

# HTTP Cache — Neon-backed with RFC2616 conditional requests.
# Scrapy sends If-Modified-Since / If-None-Match headers automatically.
# Pages returning 304 Not Modified are served from Neon cache (zero re-download).
# Set DATABASE_URL env var or in .env to enable Neon storage.
import os
_has_db = bool(os.environ.get("DATABASE_URL"))
HTTPCACHE_ENABLED = True
HTTPCACHE_POLICY = "scrapy.extensions.httpcache.RFC2616Policy"
HTTPCACHE_STORAGE = (
    "crawler.cache.neon_storage.NeonCacheStorage" if _has_db
    else "scrapy.extensions.httpcache.FilesystemCacheStorage"
)
HTTPCACHE_EXPIRATION_SECS = 86400  # 24h — refetch pages daily at most
HTTPCACHE_DIR = "crawler/.httpcache"  # fallback when no DATABASE_URL
HTTPCACHE_GZIP = True
HTTPCACHE_IGNORE_HTTP_CODES = [500, 502, 503, 504]

# AutoThrottle — adapts to server response time
AUTOTHROTTLE_ENABLED = True
AUTOTHROTTLE_START_DELAY = 1
AUTOTHROTTLE_TARGET_CONCURRENCY = 2.0
AUTOTHROTTLE_MAX_DELAY = 30

# Retry
RETRY_ENABLED = True
RETRY_TIMES = 3
RETRY_HTTP_CODES = [500, 502, 503, 504, 522, 524, 408, 429]

# Logging
LOG_LEVEL = "INFO"
LOG_FORMAT = "%(asctime)s [%(name)s] %(levelname)s: %(message)s"

# Request fingerprinting
REQUEST_FINGERPRINTER_IMPLEMENTATION = "2.7"
TWISTED_REACTOR = "twisted.internet.asyncioreactor.AsyncioSelectorReactor"
FEED_EXPORT_ENCODING = "utf-8"
