import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { SpiderDirective } from "../directives/spider.js";
import { generateSpider } from "../generators/spider-gen.js";

export function create(directivePath: string, outputDir?: string): void {
  const raw = readFileSync(directivePath, "utf-8");
  const parsed = JSON.parse(raw);
  const directive = SpiderDirective.parse(parsed);

  const python = generateSpider(directive);
  const outDir = outputDir ?? join(process.cwd(), "crawler/spiders");
  const outPath = join(outDir, `${directive.name.replace(/-/g, "_")}.py`);

  if (!existsSync(dirname(outPath))) mkdirSync(dirname(outPath), { recursive: true });
  writeFileSync(outPath, python);

  console.log(`Spider generated: ${outPath}`);
  console.log(`  Name: ${directive.name}`);
  console.log(`  Type: ${directive.type}`);
  console.log(`  Domains: ${directive.allowedDomains.join(", ")}`);
  console.log(`  Fields: ${directive.fields.map((f) => f.name).join(", ")}`);
  console.log(`  Rate: ${directive.rateLimit ? `${directive.rateLimit.downloadDelay}s delay` : "standard"}`);
}
