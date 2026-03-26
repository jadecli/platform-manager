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

# Logging
LOG_LEVEL = "INFO"
LOG_FORMAT = "%(asctime)s [%(name)s] %(levelname)s: %(message)s"

# Request fingerprinting
REQUEST_FINGERPRINTER_IMPLEMENTATION = "2.7"
TWISTED_REACTOR = "twisted.internet.asyncioreactor.AsyncioSelectorReactor"
FEED_EXPORT_ENCODING = "utf-8"
