#!/usr/bin/env bash
# Phase 01: Install pinned runtime versions.
# Requires: PLATFORM, VERSIONS, DRY_RUN, REPO_ROOT
set -euo pipefail

source "$(dirname "$0")/../install.sh" 2>/dev/null || true

NODE_VER=$(jq -r '.runtime.node' "$VERSIONS")
PYTHON_VER=$(jq -r '.runtime.python' "$VERSIONS")
RUST_VER=$(jq -r '.runtime.rustc' "$VERSIONS")
UV_VER=$(jq -r '.runtime."uv"' "$VERSIONS")

# --- Package manager ---
if [[ "$PLATFORM" == "darwin" ]]; then
  if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    $DRY_RUN || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  # jq needed for version parsing
  brew list jq &>/dev/null || brew install jq
elif [[ "$PLATFORM" == "linux" ]]; then
  if ! command -v jq &>/dev/null; then
    sudo apt-get update -qq && sudo apt-get install -y -qq jq curl git
  fi
fi

# --- mise (runtime version manager) ---
if ! command -v mise &>/dev/null; then
  echo "Installing mise..."
  if [[ "$PLATFORM" == "darwin" ]]; then
    $DRY_RUN || brew install mise
  else
    $DRY_RUN || curl https://mise.run | sh
  fi
fi

# --- Node.js via fnm (faster than mise for node) ---
if ! command -v fnm &>/dev/null; then
  echo "Installing fnm..."
  if [[ "$PLATFORM" == "darwin" ]]; then
    $DRY_RUN || brew install fnm
  else
    $DRY_RUN || curl -fsSL https://fnm.vercel.app/install | bash
  fi
fi

CURRENT_NODE=$(node --version 2>/dev/null | tr -d 'v' || echo "none")
if [[ "$CURRENT_NODE" != "$NODE_VER" ]]; then
  echo "Installing Node.js $NODE_VER (current: $CURRENT_NODE)..."
  $DRY_RUN || fnm install "$NODE_VER"
  $DRY_RUN || fnm default "$NODE_VER"
fi

# --- Python via mise ---
CURRENT_PYTHON=$(python3 --version 2>/dev/null | awk '{print $2}' || echo "none")
if [[ "$CURRENT_PYTHON" != "$PYTHON_VER" ]]; then
  echo "Installing Python $PYTHON_VER (current: $CURRENT_PYTHON)..."
  $DRY_RUN || mise install python@"$PYTHON_VER"
  $DRY_RUN || mise use -g python@"$PYTHON_VER"
fi

# --- Rust via rustup ---
if ! command -v rustup &>/dev/null; then
  echo "Installing rustup..."
  $DRY_RUN || curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
fi

CURRENT_RUST=$(rustc --version 2>/dev/null | awk '{print $2}' || echo "none")
if [[ "$CURRENT_RUST" != "$RUST_VER" ]]; then
  echo "Updating Rust to $RUST_VER (current: $CURRENT_RUST)..."
  $DRY_RUN || rustup update stable
fi

# --- uv (Python package manager) ---
if ! command -v uv &>/dev/null; then
  echo "Installing uv..."
  $DRY_RUN || curl -LsSf https://astral.sh/uv/install.sh | sh
fi

CURRENT_UV=$(uv --version 2>/dev/null | awk '{print $2}' || echo "none")
if [[ "$CURRENT_UV" != "$UV_VER" ]]; then
  echo "Updating uv to $UV_VER (current: $CURRENT_UV)..."
  $DRY_RUN || uv self update
fi

echo "  Node:   $(node --version 2>/dev/null || echo 'not installed')"
echo "  Python: $(python3 --version 2>/dev/null || echo 'not installed')"
echo "  Rust:   $(rustc --version 2>/dev/null | awk '{print $2}' || echo 'not installed')"
echo "  uv:     $(uv --version 2>/dev/null | awk '{print $2}' || echo 'not installed')"
