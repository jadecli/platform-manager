import { z } from "zod";
import { Platform, Arch, ToolchainEntry, RuntimeVersion } from "../primitives/platform.js";

export const BootstrapPhase = z.enum([
  "runtime",    // 01: Node, Python, Rust, uv
  "claude",     // 02: Claude Code CLI + auth + plugins
  "lsp",        // 03: Language servers
  "git",        // 04: Git config, SSH, signing
  "shell",      // 05: Zsh, antidote, starship
  "validate",   // 06: Version verification
]);

export const BootstrapDirective = z.object({
  /** Target platform */
  platform: Platform,
  arch: Arch,

  /** Pinned runtime versions */
  runtimes: z.array(RuntimeVersion),

  /** Toolchain entries (LSPs, formatters, CLIs) */
  toolchain: z.array(ToolchainEntry),

  /** Phases to run (default: all) */
  phases: z.array(BootstrapPhase).default([
    "runtime", "claude", "lsp", "git", "shell", "validate",
  ]),

  /** Claude Code version to install */
  claudeVersion: z.string(),

  /** Plugins to enable after install */
  plugins: z.array(z.object({
    name: z.string(),
    marketplace: z.string(),
  })),

  /** managed-settings.d fragments to deploy */
  managedSettings: z.array(z.object({
    filename: z.string(),
    content: z.record(z.string(), z.unknown()),
  })).optional(),

  /** Surface identity from manifest.xml */
  surface: z.object({
    email: z.string(),
    directory: z.string(),
    sshKey: z.string(),
    gpgFingerprint: z.string().optional(),
  }).optional(),

  /** Dry run — print commands without executing */
  dryRun: z.boolean().default(false),
});

export type BootstrapPhase = z.infer<typeof BootstrapPhase>;
export type BootstrapDirective = z.infer<typeof BootstrapDirective>;
