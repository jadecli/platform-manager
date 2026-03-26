#!/usr/bin/env python3
"""Live crawl test runner.

Runs spiders with strict page limits, validates output schema,
and shows random samples for human review. Avoids expensive full crawls.

Usage:
  python -m crawler.tests.sample_crawl <spider_name> [--pages N] [--show N]

Example:
  python -m crawler.tests.sample_crawl claude_docs --pages 5 --show 3
"""

import json
import random
import sys
import tempfile
from pathlib import Path
from datetime import datetime, timezone

from scrapy.crawler import CrawlerProcess

# Required fields every item must have
REQUIRED_FIELDS = {"url", "crawled_at"}

# Per-spider expected fields
SPIDER_SCHEMAS: dict[str, set[str]] = {
    "claude_docs": {"url", "title", "content_hash", "content_length", "crawled_at", "type"},
    "neon_docs": {"url", "title", "content_hash", "content_length", "crawled_at", "type"},
    "platform_docs": {"url", "title", "content_hash", "content_length", "crawled_at", "type"},
    "local_files": {"url", "title", "content_hash", "content_length", "crawled_at"},
}


def run_sample(spider_name: str, max_pages: int = 5, show_count: int = 3):
    output_file = Path(tempfile.mktemp(suffix=".jsonl"))

    settings = {
        "SPIDER_MODULES": ["crawler.spiders"],
        "CLOSESPIDER_ITEMCOUNT": max_pages,
        "CLOSESPIDER_TIMEOUT": 60,
        "LOG_LEVEL": "WARNING",
        "FEEDS": {str(output_file): {"format": "jsonl", "overwrite": True}},
        "ROBOTSTXT_OBEY": True,
        "REQUEST_FINGERPRINTER_IMPLEMENTATION": "2.7",
        "TWISTED_REACTOR": "twisted.internet.asyncioreactor.AsyncioSelectorReactor",
    }

    process = CrawlerProcess(settings)
    process.crawl(spider_name)
    process.start()

    if not output_file.exists() or output_file.stat().st_size == 0:
        print(f"\n❌ FAIL: Spider '{spider_name}' produced no output")
        return False

    items = [json.loads(line) for line in output_file.read_text().strip().splitlines()]
    print(f"\n{'='*60}")
    print(f"SAMPLE CRAWL: {spider_name}")
    print(f"{'='*60}")
    print(f"Items collected: {len(items)}")
    print(f"Max requested:   {max_pages}")

    # Schema validation
    expected = SPIDER_SCHEMAS.get(spider_name, REQUIRED_FIELDS)
    errors = []
    for i, item in enumerate(items):
        missing = expected - set(item.keys())
        if missing:
            errors.append(f"  Item {i}: missing {missing}")
        if not item.get("url"):
            errors.append(f"  Item {i}: empty url")

    if errors:
        print(f"\n❌ SCHEMA ERRORS ({len(errors)}):")
        for e in errors:
            print(e)
    else:
        print(f"\n✓ Schema valid: all {len(items)} items have {expected}")

    # Stats
    urls = [item["url"] for item in items]
    domains = {url.split("/")[2] for url in urls if url.startswith("http")}
    lengths = [item.get("content_length", 0) for item in items]
    print(f"\nDomains: {', '.join(domains) or 'local'}")
    print(f"Content size: min={min(lengths)}, max={max(lengths)}, avg={sum(lengths)//max(len(lengths),1)}")

    # Random samples
    samples = random.sample(items, min(show_count, len(items)))
    print(f"\n--- RANDOM SAMPLES ({len(samples)}) ---")
    for item in samples:
        print(f"\n  URL:    {item.get('url', '?')}")
        print(f"  Title:  {item.get('title', '?')[:80]}")
        print(f"  Type:   {item.get('type', '?')}")
        print(f"  Hash:   {item.get('content_hash', '?')[:16]}...")
        print(f"  Length: {item.get('content_length', '?')}")
        if item.get("changed") is not None:
            print(f"  Changed: {item['changed']}")

    # Telemetry
    telemetry = {
        "spider": spider_name,
        "test_run": True,
        "items": len(items),
        "max_pages": max_pages,
        "errors": len(errors),
        "domains": list(domains),
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
    telemetry_dir = Path("crawler/telemetry")
    telemetry_dir.mkdir(parents=True, exist_ok=True)
    with (telemetry_dir / "test-runs.jsonl").open("a") as f:
        f.write(json.dumps(telemetry) + "\n")

    output_file.unlink(missing_ok=True)

    ok = len(errors) == 0 and len(items) > 0
    print(f"\n{'✓ PASS' if ok else '❌ FAIL'}: {spider_name} sample crawl")
    return ok


if __name__ == "__main__":
    spider = sys.argv[1] if len(sys.argv) > 1 else "claude_docs"
    pages = 5
    show = 3

    for i, arg in enumerate(sys.argv):
        if arg == "--pages" and i + 1 < len(sys.argv):
            pages = int(sys.argv[i + 1])
        if arg == "--show" and i + 1 < len(sys.argv):
            show = int(sys.argv[i + 1])

    ok = run_sample(spider, max_pages=pages, show_count=show)
    sys.exit(0 if ok else 1)
