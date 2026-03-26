import { z } from "zod";

/**
 * CRITICAL: jadecli uses Claude Pro Max OAuth tokens, NOT ANTHROPIC_API_KEY.
 *
 * Authentication flow:
 *   Local:  `claude auth login` → OAuth token stored in ~/.claude/
 *   CI/CD:  ANTHROPIC_AUTH_TOKEN repo secret (from Pro Max OAuth, NOT Console API key)
 *   Per-surface: each identity (alex@, jade@, etc.) has its own OAuth token
 *
 * NEVER use:
 *   ✗ ANTHROPIC_API_KEY env var
 *   ✗ Console API billing
 *   ✗ --api-key flag
 *
 * ALWAYS use:
 *   ✓ claude auth login (interactive OAuth)
 *   ✓ ANTHROPIC_AUTH_TOKEN in GitHub repo secrets
 */

export const ClaudeAuthMethod = z.enum([
  "oauth",       // Pro/Pro Max subscription OAuth — the ONLY method we use
  "api-key",     // Console API key — NEVER use in jadecli
]);

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
  /**
   * Claude auth method for agentic operations.
   * Default: "oauth" — uses Pro Max subscription token.
   * The "api-key" option exists only for completeness — NEVER use it in jadecli.
   */
  claudeAuth: ClaudeAuthMethod.default("oauth"),
  /** GitHub Actions secret name for the OAuth token */
  githubSecretName: z.string().default("ANTHROPIC_AUTH_TOKEN"),
});

export type AuthConfig = z.infer<typeof AuthConfig>;
export type ClaudeAuthMethod = z.infer<typeof ClaudeAuthMethod>;
