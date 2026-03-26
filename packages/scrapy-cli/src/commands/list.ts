import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";

export function list(): void {
  const spidersDir = join(process.cwd(), "crawler/spiders");

  let files: string[];
  try {
    files = readdirSync(spidersDir).filter(
      (f) => f.endsWith(".py") && f !== "__init__.py",
    );
  } catch {
    console.error("No crawler/spiders/ directory found.");
    process.exit(1);
  }

  console.log(`Spiders in ${spidersDir}:\n`);

  for (const file of files) {
    const content = readFileSync(join(spidersDir, file), "utf-8");
    const nameMatch = content.match(/name\s*=\s*["']([^"']+)["']/);
    const domainsMatch = content.match(/allowed_domains\s*=\s*\[([^\]]+)\]/);
    const docMatch = content.match(/"""([\s\S]*?)"""/);

    const name = nameMatch?.[1] ?? file.replace(".py", "");
    const domains = domainsMatch?.[1]?.replace(/['"]/g, "").trim() ?? "—";
    const desc = docMatch?.[1]?.trim().split("\n")[0] ?? "—";

    console.log(`  ${name}`);
    console.log(`    File: ${file}`);
    console.log(`    Domains: ${domains}`);
    console.log(`    ${desc}`);
    console.log();
  }
}
