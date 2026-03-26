#!/usr/bin/env node
/**
 * @jadecli/scrapy-cli — TypeScript-driven Scrapy spider management.
 *
 * Usage:
 *   scrapy-cli create <directive.json> [--out <dir>]
 *   scrapy-cli run <spider-name> [-- scrapy-args...]
 *   scrapy-cli list
 *   scrapy-cli status
 *   scrapy-cli validate <directive.json>
 */

import { readFileSync } from "node:fs";
import { SpiderDirective } from "./directives/spider.js";
import { create } from "./commands/create.js";
import { run } from "./commands/run.js";
import { list } from "./commands/list.js";
import { status } from "./commands/status.js";

const args = process.argv.slice(2);
const cmd = args[0];

switch (cmd) {
  case "create": {
    const file = args[1];
    if (!file) {
      console.error("Usage: scrapy-cli create <directive.json> [--out <dir>]");
      process.exit(1);
    }
    const outIdx = args.indexOf("--out");
    const outDir = outIdx !== -1 ? args[outIdx + 1] : undefined;
    create(file, outDir);
    break;
  }

  case "run": {
    const spider = args[1];
    if (!spider) {
      console.error("Usage: scrapy-cli run <spider-name> [-- scrapy-args...]");
      process.exit(1);
    }
    const dashIdx = args.indexOf("--");
    const extraArgs = dashIdx !== -1 ? args.slice(dashIdx + 1) : [];
    run(spider, extraArgs);
    break;
  }

  case "list":
    list();
    break;

  case "status":
    status();
    break;

  case "validate": {
    const file = args[1];
    if (!file) {
      console.error("Usage: scrapy-cli validate <directive.json>");
      process.exit(1);
    }
    try {
      const raw = JSON.parse(readFileSync(file, "utf-8"));
      const result = SpiderDirective.safeParse(raw);
      if (result.success) {
        console.log(`Valid SpiderDirective: ${result.data.name}`);
        console.log(`  Type: ${result.data.type}`);
        console.log(`  Fields: ${result.data.fields.length}`);
        console.log(`  Domains: ${result.data.allowedDomains.join(", ")}`);
      } else {
        console.error("Validation errors:");
        for (const issue of result.error.issues) {
          console.error(`  ${issue.path.join(".")}: ${issue.message}`);
        }
        process.exit(1);
      }
    } catch (e) {
      console.error(`Failed to parse ${file}: ${e}`);
      process.exit(1);
    }
    break;
  }

  default:
    console.log(`@jadecli/scrapy-cli v0.1.0

Commands:
  create <directive.json> [--out <dir>]   Generate Python spider from directive
  run <spider-name> [-- args...]          Run spider via scrapy crawl
  list                                    List all spiders
  status                                  Show crawl index status
  validate <directive.json>               Validate a spider directive`);
}
