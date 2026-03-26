"""Spider: crawls docs.netlify.com/llms.txt and linked doc pages.

Netlify docs: ~78 pages across 9 sections.
Astro/Starlight-based. Content in <main> tag.
Plugin: netlify-skills@netlify-context-and-tools installed for platform features.
"""

import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

import scrapy


class NetlifyDocsSpider(scrapy.Spider):
    name = "netlify_docs"
    allowed_domains = ["docs.netlify.com"]
    start_urls = ["https://docs.netlify.com/llms.txt"]

    custom_settings = {
        "DOWNLOAD_DELAY": 2.0,
        "CONCURRENT_REQUESTS": 2,
        "CONCURRENT_REQUESTS_PER_DOMAIN": 2,
        "AUTOTHROTTLE_ENABLED": True,
        "AUTOTHROTTLE_TARGET_CONCURRENCY": 1.0,
    }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.index_path = Path("crawler/indexes/netlify_docs-index.json")
        self.previous = json.loads(self.index_path.read_text()) if self.index_path.exists() else {}

    def parse(self, response):
        text = response.text
        yield {
            "url": response.url,
            "type": "index",
            "title": "netlify-llms.txt",
            "content_hash": hashlib.sha256(text.encode()).hexdigest(),
            "content_length": len(text),
            "crawled_at": datetime.now(timezone.utc).isoformat(),
            "changed": self._changed(response.url, text),
        }

        for line in text.splitlines():
            line = line.strip()
            if line.startswith("https://docs.netlify.com/"):
                yield scrapy.Request(line, callback=self.parse_doc)

    def parse_doc(self, response):
        title = response.css("title::text").get("").strip()
        body = response.css("main").get() or response.text

        yield {
            "url": response.url,
            "type": "doc",
            "title": title,
            "content_hash": hashlib.sha256(body.encode()).hexdigest(),
            "content_length": len(body),
            "crawled_at": datetime.now(timezone.utc).isoformat(),
            "changed": self._changed(response.url, body),
        }

    def _changed(self, url: str, content: str) -> bool:
        prev_hash = self.previous.get(url, {}).get("content_hash", "")
        return hashlib.sha256(content.encode()).hexdigest() != prev_hash
