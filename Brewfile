# platform-manager Brewfile
# Aligned with anthropics/ repo toolchain as of 2026-03-25
#
# Anthropic CI pins:
#   Node 20 (sdk-typescript, code-action @types/node ^20)
#   Bun 1.2.12 (claude-code-action CI)
#   Python >=3.9 (sdk-python), >=3.10 (agent-sdk), 3.11 (cookbooks)
#   uv >=0.9 (CI: 0.10.2)
#   TypeScript 5.8.3 (sdk + action)

# --- Taps ---
tap "oven-sh/bun"
tap "stainless-api/tap"

# --- Runtimes (managed via fnm/mise, Homebrew as fallback) ---
brew "node"               # Homebrew latest; fnm manages 20/22 for project compat
brew "node@20"            # Anthropic CI standard — install for SDK testing
brew "python@3.14"
brew "python@3.11"        # claude-cookbooks CI pin
brew "oven-sh/bun/bun"    # claude-code-action runtime

# --- Version/environment managers ---
brew "fnm"                # Node version switching (Anthropic repos don't pin .nvmrc)
brew "mise"               # Polyglot runtime manager

# --- Package managers & build tools ---
# uv installed via: curl -LsSf https://astral.sh/uv/install.sh | sh
# (or: mise install uv)
brew "pre-commit"         # claude-cookbooks uses ruff pre-commit hooks

# --- GitHub & Git ---
brew "gh"                 # GitHub CLI — used in all drift-check tasks
brew "git"
brew "git-delta"          # Diff pager
brew "git-lfs"
brew "git-cliff"          # Changelog generation
brew "gitleaks"           # Secret scanning (aligns with claude-code-security-review)
brew "graphite"           # Stacked PRs (stainless-api workflow)

# --- Claude Code ecosystem ---
brew "claude-squad"       # Multi-session Claude Code orchestrator
brew "github-mcp-server"  # MCP server for GitHub (Anthropic fork)
brew "slack-mcp-server"   # MCP server for Slack integration
brew "neonctl"            # Neon Postgres CLI (enabled plugin)

# --- Linters & formatters (match Anthropic repos) ---
brew "shellcheck"         # Shell linting
brew "shfmt"              # Shell formatting
brew "taplo"              # TOML formatting/LSP (pyproject.toml heavy ecosystem)

# --- LSP servers ---
brew "lua-language-server"
brew "gopls"

# --- CLI utilities ---
brew "jq"                 # JSON processing (drift-check tasks)
brew "yq"                 # YAML processing
brew "ripgrep"            # Code search
brew "bat"                # Syntax-highlighted cat
brew "fd"                 # Fast find
brew "eza"                # Modern ls
brew "fzf"                # Fuzzy finder
brew "watchman"           # File watching (used by Jest in sdk-typescript)
brew "tmux"               # Session persistence for Claude Code remote-control
brew "starship"           # Shell prompt

# --- Casks ---
cask "1password"
cask "claude-devtools"
cask "cursor"
cask "docker-desktop"
cask "ghostty"
cask "iterm2"
cask "visual-studio-code" # VS Code Insiders installed separately
cask "alacritty"
cask "raycast"
cask "font-jetbrains-mono-nerd-font"
cask "font-fira-code-nerd-font"
