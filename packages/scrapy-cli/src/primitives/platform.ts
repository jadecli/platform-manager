import { z } from "zod";

export const Platform = z.enum(["darwin", "linux"]);

export const Arch = z.enum(["arm64", "x86_64"]);

export const PackageManager = z.enum([
  "brew",       // macOS: Homebrew
  "apt",        // Linux: Debian/Ubuntu
  "npm",        // Node.js packages (global)
  "uv",         // Python tool installs
  "mise",       // Runtime version management (node, python, go)
  "fnm",        // Fast Node Manager (backup for mise)
  "rustup",     // Rust toolchain
  "cargo",      // Rust packages
]);

export const RuntimeVersion = z.object({
  name: z.string(),
  version: z.string(),
  installer: PackageManager,
  /** Verification command — must output version string */
  verify: z.string(),
  /** Platform-specific overrides */
  platformOverrides: z.record(Platform, z.object({
    installer: PackageManager.optional(),
    package: z.string().optional(),
  })).optional(),
});

export const ToolchainEntry = z.object({
  name: z.string(),
  version: z.string(),
  installer: PackageManager,
  /** npm/uv/cargo package name if different from name */
  package: z.string().optional(),
  verify: z.string(),
  /** Only install on these platforms (default: all) */
  platforms: z.array(Platform).optional(),
  /** Category for grouping */
  category: z.enum(["runtime", "lsp", "formatter", "linter", "cli", "shell", "security", "infra"]),
});

export const PlatformConfig = z.object({
  platform: Platform,
  arch: Arch,
  /** Homebrew prefix (macOS: /opt/homebrew, Linux: /home/linuxbrew) */
  brewPrefix: z.string(),
  /** Shell config dir */
  shellConfigDir: z.string(),
  /** SSH key dir */
  sshDir: z.string().default("~/.ssh"),
  /** Claude config dir */
  claudeConfigDir: z.string().default("~/.claude"),
});

export type Platform = z.infer<typeof Platform>;
export type Arch = z.infer<typeof Arch>;
export type PackageManager = z.infer<typeof PackageManager>;
export type RuntimeVersion = z.infer<typeof RuntimeVersion>;
export type ToolchainEntry = z.infer<typeof ToolchainEntry>;
export type PlatformConfig = z.infer<typeof PlatformConfig>;
