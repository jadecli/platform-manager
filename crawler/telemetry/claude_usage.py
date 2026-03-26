"""Claude token and tool call usage tracker.

Reads Claude session telemetry from env/files and appends to
crawler/telemetry/claude-usage.jsonl. Call after agentic crawl operations.

Usage:
  from crawler.telemetry.claude_usage import track_usage
  track_usage(operation="crawl", spider="claude_docs", tokens=12345, tool_calls=8)
"""

import json
import os
from datetime import datetime, timezone
from pathlib import Path


USAGE_PATH = Path("crawler/telemetry/claude-usage.jsonl")


def track_usage(
    operation: str,
    spider: str | None = None,
    tokens: int = 0,
    tool_calls: int = 0,
    duration_ms: int = 0,
    model: str | None = None,
    cost_usd: float = 0.0,
    metadata: dict | None = None,
):
    """Append a Claude usage entry to the telemetry log."""
    USAGE_PATH.parent.mkdir(parents=True, exist_ok=True)

    entry = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "operation": operation,
        "spider": spider,
        "model": model or os.environ.get("ANTHROPIC_DEFAULT_MODEL", "unknown"),
        "tokens": tokens,
        "tool_calls": tool_calls,
        "duration_ms": duration_ms,
        "cost_usd": cost_usd,
        "surface": os.environ.get("JADECLI_SURFACE", "unknown"),
        "email": os.environ.get("JADECLI_EMAIL", "unknown"),
    }
    if metadata:
        entry["metadata"] = metadata

    with USAGE_PATH.open("a") as f:
        f.write(json.dumps(entry) + "\n")


def summary(last_n: int = 10) -> dict:
    """Summarize recent Claude usage."""
    if not USAGE_PATH.exists():
        return {"entries": 0}

    lines = USAGE_PATH.read_text().strip().splitlines()
    recent = [json.loads(l) for l in lines[-last_n:]]

    total_tokens = sum(e.get("tokens", 0) for e in recent)
    total_calls = sum(e.get("tool_calls", 0) for e in recent)
    total_cost = sum(e.get("cost_usd", 0) for e in recent)

    return {
        "entries": len(recent),
        "total_tokens": total_tokens,
        "total_tool_calls": total_calls,
        "total_cost_usd": round(total_cost, 4),
        "models": list({e.get("model", "?") for e in recent}),
    }
