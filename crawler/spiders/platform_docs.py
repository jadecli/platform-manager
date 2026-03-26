"""Spider: crawls platform.claude.com/llms.txt and linked doc pages.

Anthropic platform docs: ~607 pages (English only).
URL pattern: https://platform.claude.com/docs/en/{section}/{page}.md
"""

import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

import scrapy


class PlatformDocsSpider(scrapy.Spider):
    name = "platform_docs"
    allowed_domains = ["platform.claude.com"]
    start_urls = ["https://platform.claude.com/llms.txt"]

    custom_settings = {
        "DOWNLOAD_DELAY": 1.0,
        "CONCURRENT_REQUESTS": 4,
        "CONCURRENT_REQUESTS_PER_DOMAIN": 4,
        "AUTOTHROTTLE_ENABLED": True,
        "AUTOTHROTTLE_TARGET_CONCURRENCY": 2.0,
    }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.index_path = Path("crawler/indexes/platform_docs-index.json")
        self.previous = json.loads(self.index_path.read_text()) if self.index_path.exists() else {}

    def parse(self, response):
        text = response.text
        yield {
            "url": response.url,
            "type": "index",
            "title": "platform-llms.txt",
            "content_hash": hashlib.sha256(text.encode()).hexdigest(),
            "content_length": len(text),
            "crawled_at": datetime.now(timezone.utc).isoformat(),
            "changed": self._changed(response.url, text),
        }

        for line in text.splitlines():
            line = line.strip()
            # Only English docs
            if line.startswith("https://platform.claude.com/docs/en/"):
                yield scrapy.Request(line, callback=self.parse_doc)

    def parse_doc(self, response):
        text = response.text
        title = response.css("title::text").get("").strip()
        if not title:
            for line in text.splitlines()[:5]:
                if line.startswith("# "):
                    title = line[2:].strip()
                    break

        body = response.css("main").get() or text
        yield {
            "url": response.url,
            "type": "doc",
            "title": title or response.url.split("/")[-1],
            "content_hash": hashlib.sha256(body.encode()).hexdigest(),
            "content_length": len(body),
            "crawled_at": datetime.now(timezone.utc).isoformat(),
            "changed": self._changed(response.url, body),
        }

    def _changed(self, url: str, content: str) -> bool:
        prev_hash = self.previous.get(url, {}).get("content_hash", "")
        return hashlib.sha256(content.encode()).hexdigest() != prev_hash
