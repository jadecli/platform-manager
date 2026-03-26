"""DiffPipeline: detects and flags changed pages between crawls.

Compares current content_hash against the stored index.
Adds 'changed' and 'previous_hash' fields to items.
"""

import json
from pathlib import Path


class DiffPipeline:
    def open_spider(self, spider):
        index_path = Path("crawler/indexes") / f"{spider.name}-index.json"
        self.previous = {}
        if index_path.exists():
            self.previous = json.loads(index_path.read_text())
        self.changes = []

    def process_item(self, item, spider):
        url = item["url"]
        prev = self.previous.get(url, {})
        prev_hash = prev.get("content_hash", "")
        changed = item["content_hash"] != prev_hash

        item["changed"] = changed
        item["previous_hash"] = prev_hash

        if changed and prev_hash:
            self.changes.append({
                "url": url,
                "title": item.get("title", ""),
                "previous_hash": prev_hash,
                "new_hash": item["content_hash"],
                "crawled_at": item["crawled_at"],
            })

        return item

    def close_spider(self, spider):
        if self.changes:
            spider.logger.info(f"Detected {len(self.changes)} changed pages")
        else:
            spider.logger.info("No changes detected since last crawl")
