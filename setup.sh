#!/bin/bash
set -euo pipefail

DOTFILES="${HOME}/dotfiles"
BACKUP_DIR="${HOME}/.dotfiles_backup"

mkdir -p "${HOME}/.config"
mkdir -p "${BACKUP_DIR}"

backup_and_link() {
  local src="$1"
  local dest="$2"
  local filename backup_path
  filename="$(basename "$dest")"
  backup_path="${BACKUP_DIR}/${filename}.backup.$(date +%Y%m%d%H%M%S)"

  # 🛡 Skip if already correctly symlinked
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "⚠️  $dest already symlinks to $src — skipping"
    return
  fi

  # Backup existing non-symlink (file/dir)
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    mv "$dest" "$backup_path"
    echo "💾 Backed up $dest to $backup_path"
  fi

  # -n: do not follow symlink if dest is a symlink to a dir
  ln -sfn "$src" "$dest"
  echo "🔗 Linked $src -> $dest"
}

echo "🔧 Symlinking config files with backups to ${BACKUP_DIR}..."
backup_and_link "${DOTFILES}/.zprofile"                "${HOME}/.zprofile"
backup_and_link "${DOTFILES}/.zshrc"                   "${HOME}/.zshrc"
backup_and_link "${DOTFILES}/.envrc"                   "${HOME}/.envrc"
backup_and_link "${DOTFILES}/config/nvim"              "${HOME}/.config/nvim"
backup_and_link "${DOTFILES}/config/ghostty"           "${HOME}/.config/ghostty"
backup_and_link "${DOTFILES}/config/starship.toml"     "${HOME}/.config/starship.toml"
# Enables nix-command and flakes globally so subsequent nix/make invocations
# don't need --extra-experimental-features. Must be linked before make targets run.
mkdir -p "${HOME}/.config/nix"
backup_and_link "${DOTFILES}/config/nix/nix.conf"     "${HOME}/.config/nix/nix.conf"

# Claude Code global preferences (settings + status line). Only these curated files
# are versioned; the rest of ~/.claude (transcripts, history, sessions, caches) is not.
mkdir -p "${HOME}/.claude"
backup_and_link "${DOTFILES}/claude/settings.json"    "${HOME}/.claude/settings.json"
backup_and_link "${DOTFILES}/claude/statusline.sh"    "${HOME}/.claude/statusline.sh"

echo "🔒 Making .sh scripts executable..."
find "${DOTFILES}" -type f -name "*.sh" -exec chmod +x {} \;

echo
echo "📄 Final symlink status:"
ls -l "${HOME}/.zprofile" "${HOME}/.zshrc" "${HOME}/.envrc" \
      "${HOME}/.config/nvim" "${HOME}/.config/ghostty" "${HOME}/.config/starship.toml" \
      "${HOME}/.claude/settings.json" "${HOME}/.claude/statusline.sh" 2>/dev/null || true

# 🐳 Docker: add aliases & print backend (no auto-start during setup)
# Requires: scripts/docker/docker-bootstrap.sh (from our earlier step)
DOCKER_HELPERS="${DOTFILES}/scripts/docker"
if [ -x "${DOCKER_HELPERS}/docker-bootstrap.sh" ]; then
  "${DOCKER_HELPERS}/docker-bootstrap.sh" --backend "${DOCKER_BACKEND:-auto}" || true
fi

# 🔧 Install global CLI tools via nix profile
echo "🔧 Installing global CLI tools via nix profile..."
if command -v nix >/dev/null 2>&1; then
  # Flag required here: setup.sh is the bootstrapper and runs before
  # ~/.config/nix/nix.conf is active in the current shell session.
  # After setup, the Makefile targets run without this flag.
  nix --extra-experimental-features 'nix-command flakes' profile install "${DOTFILES}/tools" --refresh
  echo "✅ Global CLI tools installed"
else
  echo "⚠️  nix not found — skipping global CLI tools"
fi

echo "✅ Setup script complete. Symlinks, permissions, and Docker aliases ready."

