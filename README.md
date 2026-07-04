# Erik's Dotfiles

A fully reproducible and portable macOS development environment using:

- 🧰 [Homebrew](https://brew.sh) for native apps and system-level CLI tools
- ❄️ [Nix + flakes](https://nixos.org/) for isolated, versioned dev environments
- 📂 Symbolic dotfile syncing with backup safety
- 🔁 `bootstrap.sh` for clean setup on new machines
- 🧠 Designed for Go, Rust, Zig, Odin, C/C++, JS/TS, and Python development
  


## Setup Steps  
  
```bash
git clone git@github.com:erikolson/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```


## 🧪 Global Dev Environment (Nix + direnv)
  
This project includes a flake-based development environment in `dotfiles/dev-env`.  
  
The script will automatically 'direnv allow' /dotfiles/dev-env/flake.nix in the home directory.  
This configuration will be available to any directory in '~'.    
  
To manually perform this step:  
  
```bash
echo 'use flake ~/dotfiles/dev-env' > ~/.envrc
direnv allow ~
```


## 🗂️ Where does a tool go?

Three homes, by role:

| Home | For | Loading | Examples |
|------|-----|---------|----------|
| `Brewfile` | GUI apps + macOS-only tooling | `brew bundle` | Chrome, Ghostty, Raycast, casks |
| `tools/flake.nix` | Global CLI tools, always on `PATH` | `nix profile` (via `setup.sh` / `make tools`) | ripgrep, gh, helix |
| `dev-env/flake.nix` | Per-project toolchains + LSPs | direnv `use flake` on `cd ~` | go, rustc, pyright, prettier |

Rule of thumb: portable CLI tools you always want available → `tools/`; language toolchains/LSPs → `dev-env/`; GUI/macOS-only → `Brewfile`.

### 📌 Roadmap / migration notes

- **Migrate `nvim` from Brew → `tools/flake.nix`** (currently in `Brewfile`). It's a global CLI editor, so `tools/` is its natural home (`helix` already lives there). Config in `config/nvim` is symlinked and package-manager-agnostic, so it's unaffected by the swap. Steps: add `pkgs.neovim` to `tools/flake.nix`, remove `brew "neovim"` from `Brewfile`, run `make tools` + `brew bundle cleanup` (preview first), then confirm `which nvim` points at `~/.nix-profile/bin`. Deferred intentionally — no rush. See also the "move global CLI tools to a Nix profile" note in `dev-env/flake.nix`.


