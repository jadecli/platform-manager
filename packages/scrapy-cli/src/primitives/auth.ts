import { z } from "zod";

export const ProxyConfig = z.object({
  /** Proxy URL or env var reference (e.g., "$HTTP_PROXY") */
  url: z.string(),
  /** Rotate proxies from a list */
  rotate: z.boolean().default(false),
  /** Proxy list file path (one per line) */
  listPath: z.string().optional(),
});

export const AuthConfig = z.object({
  /** HTTP Basic auth */
  httpUser: z.string().optional(),
  httpPass: z.string().optional(),
  /** Cookie-based auth: cookies to inject */
  cookies: z.record(z.string(), z.string()).optional(),
  /** Custom headers */
  headers: z.record(z.string(), z.string()).optional(),
  /** User-Agent string or "rotate" for random rotation */
  userAgent: z.string().default("jadecli-platform-crawler/0.1"),
  proxy: ProxyConfig.optional(),
});

export type AuthConfig = z.infer<typeof AuthConfig>;
