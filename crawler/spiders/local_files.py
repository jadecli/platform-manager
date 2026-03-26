"""Spider: crawls local files to maintain a documentation index.

Indexes CLAUDE.md, manifest.xml, synthesis.xml, dotfiles.xml, change-plan.xml,
and any other documentation files in the ecosystem. Tracks last-modified times
and content hashes for drift detection.
"""

import hashlib
import os
from datetime import datetime, timezone
from pathlib import Path

import scrapy


class LocalFilesSpider(scrapy.Spider):
    name = "local_files"

    # Patterns to index
    PATTERNS = [
        "/Users/alexzh/jadecli-ecosystem/**/*.xml",
        "/Users/alexzh/jadecli-ecosystem/**/*.md",
        "/Users/alexzh/jadecli-ecosystem/**/CLAUDE.md",
        "/Users/alexzh/jadecli-ecosystem/shared/**/*",
        "/Users/alexzh/jadecli-ecosystem/scripts/*.sh",
        "/Users/alexzh/jadecli-ecosystem/**/.claude/settings.json",
    ]

    # Skip patterns
    SKIP = {".git", "node_modules", "__pycache__", ".venv", "repos"}

    custom_settings = {
        "ITEM_PIPELINES": {
            "crawler.pipelines.IndexPipeline": 300,
        },
    }

    def start_requests(self):
        """No HTTP requests — yield items directly from filesystem."""
        root = Path("/Users/alexzh/jadecli-ecosystem")
        seen = set()

        for pattern in self.PATTERNS:
            for path in Path("/").glob(pattern.lstrip("/")):
                if any(skip in path.parts for skip in self.SKIP):
                    continue
                if path.is_file() and path not in seen:
                    seen.add(path)
                    yield from self._index_file(path, root)

        # Dummy request to satisfy Scrapy's requirement
        yield scrapy.Request("file:///dev/null", callback=self._noop, dont_filter=True)

    def _index_file(self, path: Path, root: Path):
        try:
            content = path.read_text(errors="replace")
            stat = path.stat()
        except (OSError, PermissionError):
            return

        rel = str(path.relative_to(root)) if str(path).startswith(str(root)) else str(path)
        content_hash = hashlib.sha256(content.encode()).hexdigest()

        yield {
            "url": f"file://{path}",
            "type": "local",
            "title": rel,
            "content_hash": content_hash,
            "content_length": len(content),
            "last_modified": datetime.fromtimestamp(stat.st_mtime, tz=timezone.utc).isoformat(),
            "crawled_at": datetime.now(timezone.utc).isoformat(),
        }

    def _noop(self, response):
        pass
