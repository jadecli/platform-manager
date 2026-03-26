#!/usr/bin/env python3
"""Agentic crawler runner.

Usage:
  python -m crawler.run docs     # Crawl code.claude.com/docs
  python -m crawler.run local    # Index local ecosystem files
  python -m crawler.run all      # Both
  python -m crawler.run changes  # Show recent changelog entries
"""

import json
import sys
from pathlib import Path

from scrapy.crawler import CrawlerProcess
from scrapy.utils.project import get_project_settings


def run_spider(spider_name: str):
    settings = get_project_settings()
    process = CrawlerProcess(settings)
    process.crawl(spider_name)
    process.start()


def show_changes(n: int = 20):
    changelog = Path("crawler/indexes/changelog.jsonl")
    if not changelog.exists():
        print("No changelog yet. Run a crawl first.")
        return

    lines = changelog.read_text().strip().splitlines()
    recent = lines[-n:] if len(lines) > n else lines
    print(f"Last {len(recent)} changes:\n")
    for line in recent:
        entry = json.loads(line)
        changed = "CHANGED" if entry.get("previous_hash") else "NEW"
        print(f"  [{changed}] {entry['title']}")
        print(f"         {entry['url']}")
        print(f"         {entry['crawled_at']}")
        print()


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    cmd = sys.argv[1]
    match cmd:
        case "docs":
            run_spider("claude_docs")
        case "local":
            run_spider("local_files")
        case "all":
            settings = get_project_settings()
            process = CrawlerProcess(settings)
            process.crawl("claude_docs")
            process.crawl("local_files")
            process.start()
        case "changes":
            n = int(sys.argv[2]) if len(sys.argv) > 2 else 20
            show_changes(n)
        case _:
            print(f"Unknown command: {cmd}")
            print(__doc__)
            sys.exit(1)


if __name__ == "__main__":
    main()
