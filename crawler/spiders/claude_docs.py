"""Spider: crawls code.claude.com/docs/llms.txt and all linked doc pages.

Tracks changes daily by comparing against the last crawl index.
Outputs structured items with: url, title, content_hash, last_modified, diff_summary.
"""

import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

import scrapy


class ClaudeDocsSpider(scrapy.Spider):
    name = "claude_docs"
    allowed_domains = ["code.claude.com"]
    start_urls = ["https://code.claude.com/docs/llms.txt"]

    custom_settings = {
        "DOWNLOAD_DELAY": 0.5,
        "CONCURRENT_REQUESTS": 2,
    }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.index_path = Path("crawler/indexes/claude-docs-index.json")
        self.previous_index = self._load_previous_index()

    def _load_previous_index(self) -> dict:
        if self.index_path.exists():
            return json.loads(self.index_path.read_text())
        return {}

    def parse(self, response):
        """Parse llms.txt — extract all doc page URLs."""
        text = response.text
        for line in text.splitlines():
            line = line.strip()
            if line.startswith("https://code.claude.com/docs/"):
                yield scrapy.Request(line, callback=self.parse_doc_page)
            elif line.startswith("/en/"):
                url = f"https://code.claude.com/docs{line}"
                yield scrapy.Request(url, callback=self.parse_doc_page)

        yield {
            "url": response.url,
            "type": "index",
            "title": "llms.txt",
            "content_hash": hashlib.sha256(text.encode()).hexdigest(),
            "content_length": len(text),
            "crawled_at": datetime.now(timezone.utc).isoformat(),
            "changed": self._detect_change(response.url, text),
        }

    def parse_doc_page(self, response):
        """Parse individual doc page — extract title, content, hash."""
        title = response.css("title::text").get("").strip()
        # Get main content, strip nav/footer
        body = response.css("main").get() or response.text
        content_hash = hashlib.sha256(body.encode()).hexdigest()

        yield {
            "url": response.url,
            "type": "doc",
            "title": title,
            "content_hash": content_hash,
            "content_length": len(body),
            "crawled_at": datetime.now(timezone.utc).isoformat(),
            "changed": self._detect_change(response.url, body),
        }

    def _detect_change(self, url: str, content: str) -> bool:
        prev = self.previous_index.get(url, {})
        prev_hash = prev.get("content_hash", "")
        current_hash = hashlib.sha256(content.encode()).hexdigest()
        return current_hash != prev_hash
