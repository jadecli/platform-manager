"""IndexPipeline: maintains a JSON index of all crawled pages/files.

Writes to crawler/indexes/{spider_name}-index.json after each crawl.
Format: { url: { content_hash, content_length, title, last_crawled } }
"""

import json
from pathlib import Path


class IndexPipeline:
    def open_spider(self, spider):
        self.index_dir = Path("crawler/indexes")
        self.index_dir.mkdir(parents=True, exist_ok=True)
        self.index_path = self.index_dir / f"{spider.name}-index.json"
        self.index = {}
        if self.index_path.exists():
            self.index = json.loads(self.index_path.read_text())

    def process_item(self, item, spider):
        url = item["url"]
        self.index[url] = {
            "content_hash": item["content_hash"],
            "content_length": item["content_length"],
            "title": item.get("title", ""),
            "last_crawled": item["crawled_at"],
            "type": item.get("type", "unknown"),
        }
        return item

    def close_spider(self, spider):
        self.index_path.write_text(
            json.dumps(self.index, indent=2, sort_keys=True)
        )
        spider.logger.info(f"Index updated: {len(self.index)} entries → {self.index_path}")
