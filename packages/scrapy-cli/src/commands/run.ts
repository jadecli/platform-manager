import { execSync } from "node:child_process";
import { existsSync } from "node:fs";
import { join } from "node:path";

export function run(spiderName: string, args: string[] = []): void {
  const crawlerDir = join(process.cwd(), "crawler");
  if (!existsSync(join(crawlerDir, "scrapy.cfg"))) {
    console.error("No crawler/scrapy.cfg found. Run from platform-manager root.");
    process.exit(1);
  }

  const extraArgs = args.length ? ` ${args.join(" ")}` : "";
  const cmd = `cd ${crawlerDir} && python -m scrapy crawl ${spiderName}${extraArgs}`;

  console.log(`Running: scrapy crawl ${spiderName}`);
  try {
    execSync(cmd, { stdio: "inherit", timeout: 300_000 });
  } catch (e) {
    const err = e as { status?: number };
    process.exit(err.status ?? 1);
  }
}
