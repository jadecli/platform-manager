import { z } from "zod";

export const RateLimit = z.object({
  /** Seconds between requests to the same domain */
  downloadDelay: z.number().min(0).default(1.0),
  /** Max concurrent requests globally */
  concurrentRequests: z.number().int().min(1).default(8),
  /** Max concurrent requests per domain */
  concurrentRequestsPerDomain: z.number().int().min(1).default(4),
  /** Enable AutoThrottle — adjusts delay based on server response time */
  autoThrottle: z.boolean().default(true),
  /** AutoThrottle target concurrency */
  autoThrottleTargetConcurrency: z.number().min(0.5).default(2.0),
  /** Max AutoThrottle delay */
  autoThrottleMaxDelay: z.number().min(0).default(30),
  /** Randomize download delay (0.5x to 1.5x) */
  randomizeDelay: z.boolean().default(true),
});

export type RateLimit = z.infer<typeof RateLimit>;

export const PRESETS = {
  polite: RateLimit.parse({
    downloadDelay: 3,
    concurrentRequests: 2,
    concurrentRequestsPerDomain: 1,
    autoThrottle: true,
    autoThrottleTargetConcurrency: 1.0,
    autoThrottleMaxDelay: 60,
    randomizeDelay: true,
  }),
  standard: RateLimit.parse({
    downloadDelay: 1,
    concurrentRequests: 8,
    concurrentRequestsPerDomain: 4,
    autoThrottle: true,
    autoThrottleTargetConcurrency: 2.0,
    autoThrottleMaxDelay: 30,
    randomizeDelay: true,
  }),
  aggressive: RateLimit.parse({
    downloadDelay: 0.25,
    concurrentRequests: 32,
    concurrentRequestsPerDomain: 16,
    autoThrottle: false,
    autoThrottleTargetConcurrency: 4.0,
    autoThrottleMaxDelay: 10,
    randomizeDelay: false,
  }),
  local: RateLimit.parse({
    downloadDelay: 0,
    concurrentRequests: 64,
    concurrentRequestsPerDomain: 64,
    autoThrottle: false,
    autoThrottleTargetConcurrency: 8.0,
    autoThrottleMaxDelay: 0,
    randomizeDelay: false,
  }),
} as const satisfies Record<string, RateLimit>;
