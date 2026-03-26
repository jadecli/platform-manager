import { z } from "zod";

export const Marketplace = z.enum([
  "community",      // anthropics/claude-plugins-community (500)
  "official",       // anthropics/claude-plugins-official (119)
  "knowledge-work", // anthropics/knowledge-work-plugins (38)
  "skills",         // anthropics/skills (3)
]);

export const PluginSource = z.object({
  source: z.enum(["url", "git-subdir", "string"]),
  url: z.string().optional(),
  path: z.string().optional(),
  ref: z.string().optional(),
  sha: z.string(),
});

export const PluginEntry = z.object({
  name: z.string(),
  description: z.string().nullable(),
  source: z.union([PluginSource, z.string()]),
  homepage: z.string().optional(),
});

export const MarketplaceManifest = z.object({
  name: z.string(),
  owner: z.object({ name: z.string() }),
  plugins: z.array(PluginEntry),
});

export const PluginCrawlPhase = z.enum([
  "index",  // Fetch marketplace.json → insert/update dim_plugin
  "deep",   // Clone source repos → extract metadata → dim_plugin_metadata
  "diff",   // Compare current vs previous crawl → fact_plugin_crawl
]);

export const PluginCrawlDirective = z.object({
  marketplaces: z.array(Marketplace).default(["community", "official", "knowledge-work", "skills"]),
  phases: z.array(PluginCrawlPhase).default(["index", "deep", "diff"]),
  /** Max plugins to deep-crawl per run (0 = all) */
  batchSize: z.number().default(50),
  /** Only crawl plugins matching these categories */
  filterCategories: z.array(z.string()).optional(),
  /** Skip plugins already crawled at this SHA */
  skipUnchanged: z.boolean().default(true),
  /** GitHub token for API auth (5000 req/hr) */
  githubTokenCmd: z.string().default("gh auth token"),
});

export type Marketplace = z.infer<typeof Marketplace>;
export type PluginEntry = z.infer<typeof PluginEntry>;
export type MarketplaceManifest = z.infer<typeof MarketplaceManifest>;
export type PluginCrawlDirective = z.infer<typeof PluginCrawlDirective>;
