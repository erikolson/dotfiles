# === Zsh Config ===

# Load direnv (project shell environments)
eval "$(direnv hook zsh)"

# Load starship prompt (modern prompt with git/path info)
eval "$(starship init zsh)"

# Completion system (nix profile tools install completions to site-functions)
fpath=(~/.nix-profile/share/zsh/site-functions $fpath)
autoload -Uz compinit && compinit

# Set editor
export EDITOR="nvim"

# Add ~/bin to path if you use it
export PATH="$HOME/bin:$PATH"

# Aliases
alias ll='ls -lah'
alias dev='nix develop ~/dotfiles/dev-env'

# Optional: list files on cd
cd() { builtin cd "$@" && ls; }

# Load machine-specific overrides if they exist
if [ -f "$HOME/.zshrc.local" ]; then
  source "$HOME/.zshrc.local"
fi

# Open files or vaults in Obsidian
obs() {
  # If an argument is provided, open that file/vault. Otherwise, just open the app.
  open -a "Obsidian" "$1"
}
# --- docker dotfiles aliases ---
alias docker-desktop='open -a Docker'
alias docker-colima-start='colima start'
alias docker-colima-stop='colima stop'
alias docker-which-backend='
  if /usr/bin/pgrep -f "Docker Desktop.app" >/dev/null 2>&1; then
    echo "desktop"
  elif command -v colima >/dev/null 2>&1 && colima status >/dev/null 2>&1; then
    echo "colima"
  else
    echo "none"
  fi
'
export PATH="$(go env GOPATH)/bin:$PATH"
