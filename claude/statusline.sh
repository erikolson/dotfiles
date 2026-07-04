#!/bin/bash
# Claude Code status line
# Order: model name -> current directory -> git branch -> token count -> context-usage %
#
# Reads the JSON payload Claude Code pipes to statusLine commands on stdin.
# Degrades gracefully (no fake numbers) if jq, git, or usage data are unavailable.
#
# Theme: set CLAUDE_STATUSLINE_THEME to "catppuccin" or "normal".
#   catppuccin - muted per-segment accent colors (Catppuccin Mocha palette)
#   normal     - a light, readable monochrome grey
# Context % is threshold-colored in both themes: calm when low, warns when high.
#
# WIRING (for a future session picking this up cold):
#   - Activated by the "statusLine" key in ~/.claude/settings.json, which runs
#     this script: {"type":"command","command":"bash \"$HOME/.claude/statusline.sh\""}.
#   - Input fields consumed from the stdin JSON (first-party Claude Code schema):
#       .model.display_name
#       .workspace.current_dir   (falls back to .cwd, then `pwd`)
#       .context_window.total_input_tokens
#       .context_window.used_percentage
#       .context_window.context_window_size
#   - Colors are 24-bit truecolor SGR escapes (\033[38;2;R;G;Bm). Values in the
#     catppuccin branch are Catppuccin Mocha. If a terminal lacks truecolor,
#     drop these to the 256-color palette instead.
#   - Segment order and label wording ("tokens", "ctx") were chosen deliberately;
#     token count is intentionally the brightest segment.
#   - VERSION CONTROLLED: THIS is the real file (~/dotfiles/claude/statusline.sh). It is
#     symlinked to ~/.claude/statusline.sh, so edit THIS path, not the ~/.claude one
#     (tools refuse to write through the symlink). After editing, commit in ~/dotfiles.
#     settings.json is managed the same way. Relinked on a new machine by dotfiles/setup.sh.

input="$(cat)"

THEME="${CLAUDE_STATUSLINE_THEME:-catppuccin}"

RESET='\033[0m'

if [ "$THEME" = "normal" ]; then
  COL_MODEL="180;180;180"
  COL_DIR="180;180;180"
  COL_BRANCH="180;180;180"
  COL_TOK="215;215;215"        # brightest - the detail I care about most
  COL_SEP="96;96;96"
  COL_CTX_LOW="180;180;180"    # calm
  COL_CTX_MID="205;180;120"    # ~70%+  soft amber
  COL_CTX_HIGH="214;140;140"   # ~90%+  soft red
else
  # Catppuccin Mocha
  COL_MODEL="250;179;135"      # peach (distinct from the mauve accept-edit line)
  COL_DIR="137;180;250"        # blue
  COL_BRANCH="166;227;161"     # green
  COL_TOK="205;214;244"        # text (bright/primary - the detail I care about most)
  COL_SEP="108;112;134"        # overlay0
  COL_CTX_LOW="166;173;200"    # subtext0 (calm)
  COL_CTX_MID="249;226;175"    # yellow
  COL_CTX_HIGH="243;139;168"   # red
fi

# Wrap text in a truecolor foreground color. Usage: paint "R;G;B" "text"
paint() { printf '\033[38;2;%sm%s%b' "$1" "$2" "$RESET"; }

SEP=" $(paint "$COL_SEP" '|') "

have_jq=0
command -v jq >/dev/null 2>&1 && have_jq=1

if [ "$have_jq" -eq 1 ]; then
  model="$(printf '%s' "$input" | jq -r '.model.display_name // "Claude"')"
  cwd="$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty')"
  tokens="$(printf '%s' "$input" | jq -r '.context_window.total_input_tokens // empty')"
  used_pct="$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')"
  window_size="$(printf '%s' "$input" | jq -r '.context_window.context_window_size // empty')"
else
  # No jq available: fall back to shell-only info, no JSON parsing.
  model="Claude"
  cwd=""
  tokens=""
  used_pct=""
  window_size=""
fi

[ -z "$cwd" ] && cwd="$(pwd)"
dir_name="$(basename "$cwd")"

branch=""
if command -v git >/dev/null 2>&1; then
  branch="$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)"
fi

# Convert a raw token count into a compact human-readable form (e.g. 12.3k, 1.0M).
human_tokens() {
  local n="$1"
  if [ -z "$n" ] || ! [[ "$n" =~ ^[0-9]+$ ]]; then
    printf ''
    return
  fi
  if [ "$n" -ge 1000000 ]; then
    awk -v n="$n" 'BEGIN { printf "%.1fM", n/1000000 }'
  elif [ "$n" -ge 1000 ]; then
    awk -v n="$n" 'BEGIN { printf "%.1fk", n/1000 }'
  else
    printf '%s' "$n"
  fi
}

tokens_h="$(human_tokens "$tokens")"
window_h="$(human_tokens "$window_size")"

# --- Token count segment ---
if [ -n "$tokens_h" ]; then
  if [ -n "$window_h" ]; then
    tokens_text="${tokens_h}/${window_h} tokens"
  else
    tokens_text="${tokens_h} tokens"
  fi
else
  # No usage data yet (e.g. before the first response) - say so, don't fabricate.
  tokens_text="tokens: n/a"
fi

# --- Context-usage percentage segment (with threshold color) ---
pct=""
if [ -n "$used_pct" ] && [ "$used_pct" != "null" ]; then
  # Preferred path: Claude Code already computed used_percentage for us.
  pct="$(awk -v p="$used_pct" 'BEGIN { printf "%.0f", p }')"
elif [ -n "$tokens" ] && [ -n "$window_size" ] && [ "$window_size" -gt 0 ] 2>/dev/null; then
  # Fallback: derive percentage ourselves from tokens / window size.
  pct="$(awk -v t="$tokens" -v w="$window_size" 'BEGIN { printf "%.0f", (t/w)*100 }')"
fi

if [ -n "$pct" ]; then
  ctx_text="${pct}% ctx"
  if [ "$pct" -ge 90 ] 2>/dev/null; then
    ctx_col="$COL_CTX_HIGH"
  elif [ "$pct" -ge 70 ] 2>/dev/null; then
    ctx_col="$COL_CTX_MID"
  else
    ctx_col="$COL_CTX_LOW"
  fi
else
  # Can't produce a reliable percentage - don't guess.
  ctx_text="ctx: n/a"
  ctx_col="$COL_CTX_LOW"
fi

line="$(paint "$COL_MODEL" "$model")${SEP}$(paint "$COL_DIR" "$dir_name")"
if [ -n "$branch" ]; then
  line="${line}${SEP}$(paint "$COL_BRANCH" "$branch")"
fi
line="${line}${SEP}$(paint "$COL_TOK" "$tokens_text")${SEP}$(paint "$ctx_col" "$ctx_text")"

printf "%b\n" "$line"
