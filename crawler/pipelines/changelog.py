"""ChangelogPipeline: appends changed items to a JSONL changelog.

Only records items where 'changed' is True. Each line is a JSON object
with url, title, crawled_at, content_hash, previous_hash.
Used by the agentic crawler to track what changed and when.
"""

import json
from pathlib import Path


class ChangelogPipeline:
    def open_spider(self, spider):
        self.changelog_path = Path("crawler/indexes/changelog.jsonl")
        self.changelog_path.parent.mkdir(parents=True, exist_ok=True)
        self.file = self.changelog_path.open("a")

    def process_item(self, item, spider):
        if item.get("changed") and item.get("previous_hash"):
            entry = {
                "url": item["url"],
                "title": item.get("title", ""),
                "crawled_at": item["crawled_at"],
                "content_hash": item["content_hash"],
                "previous_hash": item["previous_hash"],
                "content_length": item["content_length"],
                "spider": spider.name,
            }
            self.file.write(json.dumps(entry) + "\n")
        return item

    def close_spider(self, spider):
        self.file.close()
