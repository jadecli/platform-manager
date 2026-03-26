"""Scrapy stats collector extension.

Writes crawl telemetry to crawler/telemetry/crawl-stats.jsonl after each spider closes.
Captures: items scraped, pages fetched, errors, timing, rate limit behavior.

Enable in settings:
  EXTENSIONS = {"crawler.telemetry.stats_collector.TelemetryExtension": 500}
"""

import json
from datetime import datetime, timezone
from pathlib import Path

from scrapy import signals
from scrapy.statscollectors import StatsCollector


class TelemetryExtension:
    def __init__(self, stats: StatsCollector):
        self.stats = stats
        self.telemetry_path = Path("crawler/telemetry/crawl-stats.jsonl")
        self.telemetry_path.parent.mkdir(parents=True, exist_ok=True)

    @classmethod
    def from_crawler(cls, crawler):
        ext = cls(crawler.stats)
        crawler.signals.connect(ext.spider_closed, signal=signals.spider_closed)
        return ext

    def spider_closed(self, spider, reason):
        stats = self.stats.get_stats()

        entry = {
            "spider": spider.name,
            "reason": reason,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            # Items
            "items_scraped": stats.get("item_scraped_count", 0),
            "items_dropped": stats.get("item_dropped_count", 0),
            # Requests
            "requests_sent": stats.get("downloader/request_count", 0),
            "responses_received": stats.get("downloader/response_count", 0),
            "response_bytes": stats.get("downloader/response_bytes", 0),
            # Errors
            "errors": stats.get("spider_exceptions", {}),
            "http_errors": {
                k.replace("downloader/response_status_count/", ""): v
                for k, v in stats.items()
                if k.startswith("downloader/response_status_count/") and not k.endswith("/200")
            },
            # Timing
            "elapsed_seconds": (
                (stats.get("finish_time", datetime.now(timezone.utc))
                 - stats.get("start_time", datetime.now(timezone.utc))).total_seconds()
            ),
            # Rate limiting
            "autothrottle_delay": stats.get("autothrottle/delay", None),
            # Depth
            "max_depth": stats.get("request_depth_max", 0),
        }

        with self.telemetry_path.open("a") as f:
            f.write(json.dumps(entry, default=str) + "\n")

        spider.logger.info(
            f"Telemetry: {entry['items_scraped']} items, "
            f"{entry['requests_sent']} requests, "
            f"{entry['elapsed_seconds']:.1f}s"
        )
