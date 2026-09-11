# Erik's Dotfiles

A reproducible, portable development environment for macOS — built so a bare machine
becomes a full polyglot dev setup with a single `./bootstrap.sh`, and so the toolchain
is *pinned* rather than "whatever the package manager gave me today."

The design goal is a **reproducible substrate**: the environment is described declaratively,
versioned in git, and rebuildable on demand — not accreted by hand over years.

## Design principles

- **Reproducible** — language toolchains are pinned via [Nix flakes](https://nixos.org/) + `flake.lock`, so `rustc`/`go`/`node`/etc. are identical across machines and over time.
- **Layered** — every tool has one correct home (see the table below). Editors and CLIs that should always be on `PATH` live in a Nix profile; per-project toolchains live in a dev shell; GUI/macOS-only apps live in Homebrew.
- **Idempotent & safe** — `setup.sh` is re-runnable. It backs up any existing file to `~/.dotfiles_backup/<name>.backup.<timestamp>` before replacing it, and short-circuits if a symlink is already correct. Nothing is clobbered silently.
- **Portable** — the Nix flakes target `x86_64`/`aarch64` × `darwin`/`linux`. macOS is the daily driver today (the `bootstrap.sh` installer is macOS-only), but the toolchain layer is cross-platform by construction.

## Architecture — where does a tool go?

Three layers, chosen by role rather than habit:

| Layer | For | Loading mechanism | Examples |
|-------|-----|-------------------|----------|
| `Brewfile` | GUI apps + macOS-only tooling | `brew bundle` | Chrome, Ghostty, Raycast, 1Password, casks |
| `tools/flake.nix` | Global CLI tools, always on `PATH` | Nix profile (`nix profile`, via `setup.sh` / `make tools`) | ripgrep, GitHub CLI, helix, custom git tooling |
| `dev-env/flake.nix` | Per-project language toolchains + LSPs | direnv `use flake` on `cd ~` | go/gopls, rustc/rust-analyzer, pyright, prettier |

**Why both Nix and Homebrew?** Homebrew is best-in-class for macOS GUI apps and casks; Nix flakes give reproducible, pinned, cross-platform CLI/toolchain installs that `brew` can't. Each is used only where it's strongest. The migration direction is CLI tools → Nix over time (see Roadmap).

## What's inside

- **Languages / toolchains** (`dev-env/flake.nix`): Go, Rust, Zig, Odin, C/C++ (clang + clangd), Python, JavaScript/TypeScript (Node + Bun) — each with its language server and formatter, so LSP works out of the box in Neovim.
- **Global CLI tools** (`tools/flake.nix`): ripgrep, GitHub CLI, Helix, plus custom git tooling for process/product separation.
- **Editor**: Neovim, configured with `lazy.nvim` (config in `config/nvim`, plugins pinned via `lazy-lock.json`).
- **Terminal & prompt**: Ghostty + Starship (flake-aware nix-shell indicator).
- **Claude Code**: versioned global `settings.json` and a themed `statusline.sh` (model · dir · branch · token/context usage). Unlike every other linked file, `settings.json` is tool-mutated — Claude Code writes runtime toggles into it — so review stray diffs before committing.
- **Containers/orchestration**: Docker with switchable backends (Docker Desktop ⇄ Colima) and one-command local Kubernetes (k3d / kind / minikube).

## Quick start

```bash
git clone git@github.com:erikolson/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

`bootstrap.sh` installs Homebrew + Nix if missing, installs the `Brewfile`, then runs
`setup.sh` to symlink configs (with backups) and install the global Nix tools profile.
Restart your shell or `exec $SHELL -l` when it finishes.

## Everyday commands

Common operations are wrapped in the `Makefile`:

| Command | What it does |
|---------|--------------|
| `make update` | Update everything: `brew bundle` + `nix flake update` (dev-env) + `nix profile upgrade` (tools) |
| `make brew` | Sync Homebrew packages from the `Brewfile` |
| `make flake` | Update the dev-env flake lock |
| `make tools` | Upgrade the global Nix tools profile |
| `make dev` | Drop into the dev shell manually (`nix develop`) |
| `make doctor` | Health-check the environment (brew/nix/direnv present, symlinks in place) |
| `make versions` | Print the resolved version of every toolchain in the current shell |
| `make lint` | `shellcheck` the setup scripts |
| `make backup` | Back up existing dotfiles before changes |
| `make clean` | Garbage-collect unused Nix store paths |
| `make docker-toggle` / `docker-status` | Switch between Docker Desktop and Colima / show active backend |
| `make k8s-up K8S_DIST=k3d CLUSTER=dev` | Spin up a local Kubernetes cluster (k3d/kind/minikube) |

## How it works — notable pieces

- **Idempotent symlinking with backups** (`setup.sh`): `backup_and_link` skips already-correct symlinks, timestamps a backup of anything it would overwrite, and uses `ln -sfn` so re-runs are safe.
- **Machine-local overrides**: `~/.zshrc.local` is sourced if present (never versioned), and `.envrc` is gitignored and seeded from the tracked `.envrc.example` template — so machine-specific state stays out of git while the setup remains reproducible.
- **User-level flakes** (`config/nix/nix.conf`): enables `nix-command` and `flakes` without touching system `/etc/nix/nix.conf`.
- **Global dev shell**: direnv activates the `dev-env` flake for the whole home directory (`use flake ~/dotfiles/dev-env`), so language tools are available everywhere without a per-project `.envrc`.
- **Claude Code statusline** (`claude/statusline.sh`): a dependency-light Bash status line that degrades gracefully when `jq`/`git`/usage data are unavailable — no fabricated numbers. Two themes (Catppuccin / monochrome), threshold-colored context usage.

## Repo layout

```
.
├── bootstrap.sh          # one-shot installer (Homebrew, Nix, Brewfile, setup.sh)
├── setup.sh              # idempotent symlinking + Nix tools install
├── Makefile              # everyday operations (update, doctor, docker, k8s, …)
├── Brewfile              # macOS apps, casks, and macOS-only CLIs
├── tools/flake.nix       # global CLI tools → Nix profile
├── dev-env/flake.nix     # polyglot dev shell (toolchains + LSPs), loaded via direnv
├── config/               # nvim, ghostty, starship, nix.conf
├── claude/               # versioned Claude Code settings + statusline
└── scripts/docker/       # Docker Desktop ⇄ Colima backend switching
```

## Roadmap / notes

- **Migrate `nvim` from Brew → `tools/flake.nix`.** It's a global CLI editor, so `tools/` is its natural home (Helix already lives there). Its config in `config/nvim` is symlinked and package-manager-agnostic, so the swap is invisible to the editor setup. Steps: add `pkgs.neovim` to `tools/flake.nix`, remove `brew "neovim"` from the `Brewfile`, run `make tools` + `brew bundle cleanup` (preview first), then confirm `which nvim` points at `~/.nix-profile/bin`. Deferred intentionally — see the "move global CLI tools to a Nix profile" note in `dev-env/flake.nix`.
