import { z } from "zod";

export const SelectorType = z.enum(["css", "xpath", "regex", "jmespath"]);

export const Selector = z.object({
  type: SelectorType.default("css"),
  query: z.string(),
  /** Extract attribute instead of text (e.g., "href", "src") */
  attr: z.string().optional(),
  /** Post-processing: strip whitespace, join, first, all */
  extract: z.enum(["first", "all", "join"]).default("first"),
  /** Regex pattern applied after extraction */
  re: z.string().optional(),
  /** Default value if selector returns empty */
  default: z.string().optional(),
});

export type Selector = z.infer<typeof Selector>;

/** Field definition: name → selector mapping */
export const FieldDef = z.object({
  name: z.string(),
  selector: Selector,
  /** Python type hint for the extracted value */
  type: z.enum(["str", "int", "float", "list[str]", "bool"]).default("str"),
  required: z.boolean().default(false),
});

export type FieldDef = z.infer<typeof FieldDef>;
