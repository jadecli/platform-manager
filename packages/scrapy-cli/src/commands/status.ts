import { readFileSync, existsSync } from "node:fs";
import { join } from "node:path";

export function status(): void {
  const indexDir = join(process.cwd(), "crawler/indexes");

  if (!existsSync(indexDir)) {
    console.log("No crawl indexes found. Run a crawl first.");
    return;
  }

  // Check each index file
  const indexFiles = ["claude_docs-index.json", "local_files-index.json"];

  for (const file of indexFiles) {
    const path = join(indexDir, file);
    if (!existsSync(path)) continue;

    const index = JSON.parse(readFileSync(path, "utf-8")) as Record<
      string,
      { last_crawled: string; content_hash: string }
    >;
    const entries = Object.keys(index).length;
    const latest = Object.values(index)
      .map((v) => v.last_crawled)
      .sort()
      .pop();

    console.log(`${file}:`);
    console.log(`  Entries: ${entries}`);
    console.log(`  Last crawl: ${latest ?? "never"}`);
    console.log();
  }

  // Changelog
  const changelog = join(indexDir, "changelog.jsonl");
  if (existsSync(changelog)) {
    const lines = readFileSync(changelog, "utf-8").trim().split("\n");
    console.log(`Changelog: ${lines.length} changes recorded`);
    if (lines.length > 0) {
      const last = JSON.parse(lines[lines.length - 1]!) as { url: string; crawled_at: string };
      console.log(`  Latest: ${last.url} (${last.crawled_at})`);
    }
  }
}
