import { z } from "zod";

export const OutputFormat = z.enum(["json", "jsonl", "csv", "xml", "sqlite"]);

export const Output = z.object({
  format: OutputFormat.default("jsonl"),
  /** File path or URI for output. Supports %(name)s, %(time)s placeholders. */
  path: z.string().default("output/%(name)s-%(time)s.jsonl"),
  /** Overwrite existing file or append */
  overwrite: z.boolean().default(true),
  /** Fields to include (empty = all) */
  fields: z.array(z.string()).default([]),
  /** Encoding */
  encoding: z.string().default("utf-8"),
});

export type Output = z.infer<typeof Output>;
