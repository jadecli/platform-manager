export default {
  extends: ["@commitlint/config-conventional"],
  rules: {
    // Match Anthropic's convention
    "type-enum": [
      2,
      "always",
      [
        "feat",     // New feature
        "fix",      // Bug fix
        "docs",     // Documentation only
        "style",    // Formatting, no code change
        "refactor", // Code change that neither fixes nor adds
        "perf",     // Performance improvement
        "test",     // Adding or correcting tests
        "build",    // Build system or external dependencies
        "ci",       // CI configuration
        "chore",    // Maintenance tasks
        "revert",   // Revert a previous commit
        "security", // Security fix or audit
        "crawl",    // Crawler-specific changes
      ],
    ],
    "subject-case": [0],  // Allow any case in subject
    "body-max-line-length": [0], // No line length limit in body
  },
};
