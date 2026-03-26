import { z } from "zod";
import { RateLimit } from "../primitives/rate-limit.js";
import { FieldDef } from "../primitives/selector.js";
import { Output } from "../primitives/output.js";
import { AuthConfig } from "../primitives/auth.js";

export const SpiderType = z.enum([
  "crawl",       // CrawlSpider — follows links matching rules
  "sitemap",     // SitemapSpider — reads sitemap.xml
  "feed",        // XMLFeedSpider / CSVFeedSpider
  "api",         // API pagination spider
  "local",       // Local file indexer (no HTTP)
]);

export const LinkRule = z.object({
  /** URL pattern to follow (regex) */
  allow: z.string(),
  /** URL pattern to deny (regex) */
  deny: z.string().optional(),
  /** Callback method name for matched pages */
  callback: z.string().default("parse_item"),
  /** Follow links from matched pages */
  follow: z.boolean().default(true),
});

export const PaginationConfig = z.object({
  /** Next page selector (CSS/XPath for link, or JSON path for API) */
  nextPage: z.string(),
  /** Max pages to crawl (0 = unlimited) */
  maxPages: z.number().int().min(0).default(0),
  /** API: query param for page/offset */
  paramName: z.string().default("page"),
  /** API: increment per page */
  increment: z.number().int().default(1),
});

export const SpiderDirective = z.object({
  /** Spider name — must be unique, lowercase, hyphens ok */
  name: z.string().regex(/^[a-z][a-z0-9-]*$/),
  /** Human description of what this spider does */
  description: z.string(),
  /** Spider type determines the base class */
  type: SpiderType.default("crawl"),
  /** Domains this spider is allowed to crawl */
  allowedDomains: z.array(z.string()),
  /** Starting URLs */
  startUrls: z.array(z.string()).min(1),
  /** Fields to extract from each page */
  fields: z.array(FieldDef).min(1),
  /** Link-following rules (CrawlSpider only) */
  rules: z.array(LinkRule).optional(),
  /** Pagination config (API spiders, or any paginated listing) */
  pagination: PaginationConfig.optional(),
  /** Rate limiting */
  rateLimit: RateLimit.optional(),
  /** Output format and destination */
  output: Output.optional(),
  /** Auth and proxy settings */
  auth: AuthConfig.optional(),

  /** Custom settings override (passed to custom_settings in spider) */
  settings: z.record(z.string(), z.unknown()).optional(),
  /** Scrapy middlewares to enable/disable */
  middlewares: z.record(z.string(), z.union([z.number(), z.null()])).optional(),
  /** Scrapy pipelines to enable/disable */
  pipelines: z.record(z.string(), z.union([z.number(), z.null()])).optional(),

  /** Max depth for crawling */
  depth: z.number().int().min(0).default(0),
  /** Max items to scrape (0 = unlimited) */
  maxItems: z.number().int().min(0).default(0),
  /** Request timeout in seconds */
  timeout: z.number().min(0).default(30),
  /** Retry failed requests */
  retryTimes: z.number().int().min(0).default(3),

  /** Tags for organization */
  tags: z.array(z.string()).default([]),
});

export type SpiderDirective = z.infer<typeof SpiderDirective>;
