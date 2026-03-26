#!/usr/bin/env bash
# Phase 04: Git config, SSH keys, commit signing, includeIf identity.
set -euo pipefail

# --- Git global config ---
echo "  Configuring git defaults..."
$DRY_RUN || {
  git config --global init.defaultBranch main
  git config --global pull.rebase true
  git config --global push.autoSetupRemote true
  git config --global gpg.format ssh
  git config --global commit.gpgsign true
  git config --global tag.gpgsign true
  git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
  git config --global credential.https://github.com.helper "!$(command -v gh) auth git-credential"
}

# --- SSH key generation (if missing) ---
generate_ssh_key() {
  local name="$1" email="$2"
  local keyfile="$HOME/.ssh/$name"
  if [[ ! -f "$keyfile" ]]; then
    echo "  Generating SSH key: $name for $email"
    $DRY_RUN || ssh-keygen -t ed25519 -C "$email" -f "$keyfile" -N ""
    echo "  Add to GitHub: cat $keyfile.pub | gh ssh-key add --title '$name'"
  else
    echo "  SSH key exists: $name ✓"
  fi
}

generate_ssh_key "id_ed25519_alex_jadecli" "alex@jadecli.com"
generate_ssh_key "id_ed25519_jade_jadecli" "jade@jadecli.com"
generate_ssh_key "id_ed25519_alex" "zhouk.alex@gmail.com"

# --- SSH config ---
echo "  SSH config: ~/.ssh/config"
if ! grep -q "github-jade" ~/.ssh/config 2>/dev/null; then
  echo "  WARNING: ~/.ssh/config missing github-jade host. Run manually or copy from ecosystem."
fi

# --- Git includeIf for per-surface identity ---
echo "  Git includeIf: per-surface identity switching"
mkdir -p ~/.config/git

for surface in ghostty iterm2 toad; do
  inc_file="$HOME/.config/git/jadecli-${surface}.inc"
  if [[ ! -f "$inc_file" ]]; then
    echo "  Creating $inc_file..."
    case "$surface" in
      ghostty)
        $DRY_RUN || cat > "$inc_file" << 'INC'
[user]
	name = alex-jadecli
	email = alex@jadecli.com
	signingkey = ~/.ssh/id_ed25519_alex_jadecli.pub
INC
        ;;
      iterm2)
        $DRY_RUN || cat > "$inc_file" << 'INC'
[user]
	name = jade-jadecli
	email = jade@jadecli.com
	signingkey = ~/.ssh/id_ed25519_jade_jadecli.pub
INC
        ;;
      toad)
        $DRY_RUN || cat > "$inc_file" << 'INC'
[user]
	name = zhouk-alex
	email = zhouk.alex@gmail.com
	signingkey = ~/.ssh/id_ed25519_alex.pub
INC
        ;;
    esac
  else
    echo "  $inc_file ✓"
  fi
done

# --- Pre-push hook: block direct main pushes from agents ---
HOOK_SRC="$REPO_ROOT/bootstrap/git-hooks/pre-push"
HOOK_DST="$REPO_ROOT/.git/hooks/pre-push"
if [[ -f "$HOOK_SRC" ]]; then
  $DRY_RUN || ln -sf "$HOOK_SRC" "$HOOK_DST"
  echo "  Pre-push hook installed (blocks agent pushes to main)"
fi

# --- Verify signing works ---
echo "  Verifying commit signing..."
if git config --global user.signingkey &>/dev/null; then
  echo "  Signing key configured ✓"
else
  echo "  WARNING: No default signing key. Set in ~/.gitconfig [user] signingkey"
fi
