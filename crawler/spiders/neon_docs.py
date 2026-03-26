"""Spider: crawls neon.com/llms.txt and linked doc pages.

Neon docs: ~244 pages across 17 sections.
URL pattern: https://neon.com/docs/{section}/{page}
Append .md for markdown format.
"""

import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

import scrapy


class NeonDocsSpider(scrapy.Spider):
    name = "neon_docs"
    allowed_domains = ["neon.com"]
    start_urls = ["https://neon.com/llms.txt"]

    custom_settings = {
        "DOWNLOAD_DELAY": 1.5,
        "CONCURRENT_REQUESTS": 3,
        "CONCURRENT_REQUESTS_PER_DOMAIN": 3,
        "AUTOTHROTTLE_ENABLED": True,
        "AUTOTHROTTLE_TARGET_CONCURRENCY": 2.0,
    }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.index_path = Path("crawler/indexes/neon_docs-index.json")
        self.previous = json.loads(self.index_path.read_text()) if self.index_path.exists() else {}

    def parse(self, response):
        text = response.text
        yield {
            "url": response.url,
            "type": "index",
            "title": "neon-llms.txt",
            "content_hash": hashlib.sha256(text.encode()).hexdigest(),
            "content_length": len(text),
            "crawled_at": datetime.now(timezone.utc).isoformat(),
            "changed": self._changed(response.url, text),
        }

        for line in text.splitlines():
            line = line.strip()
            if line.startswith("https://neon.com/docs/"):
                # Fetch markdown version
                url = line.removesuffix(".md")
                if not url.endswith(".md"):
                    url += ".md"
                yield scrapy.Request(url, callback=self.parse_doc)

    def parse_doc(self, response):
        text = response.text
        title = ""
        for line in text.splitlines()[:5]:
            if line.startswith("# "):
                title = line[2:].strip()
                break

        yield {
            "url": response.url.replace(".md", ""),
            "type": "doc",
            "title": title or response.url.split("/")[-1],
            "content_hash": hashlib.sha256(text.encode()).hexdigest(),
            "content_length": len(text),
            "crawled_at": datetime.now(timezone.utc).isoformat(),
            "changed": self._changed(response.url, text),
        }

    def _changed(self, url: str, content: str) -> bool:
        prev_hash = self.previous.get(url, {}).get("content_hash", "")
        return hashlib.sha256(content.encode()).hexdigest() != prev_hash
