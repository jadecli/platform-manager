import { z } from "zod";

export const ScheduleDirective = z.object({
  /** Spider name to schedule */
  spider: z.string(),
  /** Cron expression (5-field, local timezone) */
  cron: z.string(),
  /** Enable/disable without deleting */
  enabled: z.boolean().default(true),
  /** Override spider args for this schedule */
  args: z.record(z.string(), z.string()).optional(),
  /** Max runtime in seconds before killing */
  timeout: z.number().int().min(0).default(3600),
  /** Alert on failure */
  alertOnFailure: z.boolean().default(true),
});

export type ScheduleDirective = z.infer<typeof ScheduleDirective>;
