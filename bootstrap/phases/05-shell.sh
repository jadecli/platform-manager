#!/usr/bin/env bash
# Phase 05: Shell setup — zsh, antidote, starship, core CLI tools.
set -euo pipefail

# --- macOS: brew bundle for shell tools ---
if [[ "$PLATFORM" == "darwin" ]]; then
  SHELL_TOOLS=(bat eza fd ripgrep starship antidote lazygit jq gh graphite difftastic)
  for tool in "${SHELL_TOOLS[@]}"; do
    if ! brew list "$tool" &>/dev/null; then
      echo "  Installing $tool..."
      $DRY_RUN || brew install "$tool"
    else
      echo "  $tool ✓"
    fi
  done

# --- Linux: apt equivalents ---
elif [[ "$PLATFORM" == "linux" ]]; then
  APT_TOOLS=(bat fd-find ripgrep jq)
  echo "  Installing apt packages..."
  $DRY_RUN || sudo apt-get install -y -qq "${APT_TOOLS[@]}"

  # starship via curl
  if ! command -v starship &>/dev/null; then
    echo "  Installing starship..."
    $DRY_RUN || curl -sS https://starship.rs/install.sh | sh -s -- -y
  fi

  # eza via cargo (not in apt)
  if ! command -v eza &>/dev/null; then
    echo "  Installing eza via cargo..."
    $DRY_RUN || cargo install eza
  fi

  # gh CLI
  if ! command -v gh &>/dev/null; then
    echo "  Installing GitHub CLI..."
    $DRY_RUN || {
      curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
      sudo apt-get update -qq && sudo apt-get install -y -qq gh
    }
  fi

  # lazygit
  if ! command -v lazygit &>/dev/null; then
    echo "  Installing lazygit..."
    $DRY_RUN || go install github.com/jesseduffield/lazygit@latest
  fi
fi

# --- Python CLI tools via uv ---
UV_TOOLS=(
  "detect-secrets"
  "ruff"
  "pyright"
  "conventional-pre-commit"
)
for tool in "${UV_TOOLS[@]}"; do
  if ! uv tool list 2>/dev/null | grep -q "^$tool "; then
    echo "  Installing $tool via uv..."
    $DRY_RUN || uv tool install "$tool"
  else
    echo "  $tool ✓"
  fi
done

echo "  Shell tools configured."
