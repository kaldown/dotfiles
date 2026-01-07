# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              ZSHRC - Optimized                               ║
# ║                     Target startup: <100ms (perceived <20ms)                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ══════════════════════════════════════════════════════════════════════════════
# INSTANT PROMPT (must be at the very top)
# ══════════════════════════════════════════════════════════════════════════════
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ══════════════════════════════════════════════════════════════════════════════
# ENVIRONMENT VARIABLES
# ══════════════════════════════════════════════════════════════════════════════

# For ctrl+w shortuct to read by word, respecting separation
WORDCHARS='*?[]~&;!#\$%^(){}<>'

export EDITOR=nvim
export VISUAL=nvim
export LESS='-FRKX'

# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000

# ══════════════════════════════════════════════════════════════════════════════
# PATH & TOOL SETUP (before plugins, no evals yet)
# ══════════════════════════════════════════════════════════════════════════════

# Homebrew (arm64 / x86_64)
# Used for GamePortingToolkit rosetta87 emulation
if [[ "$(arch)" == "arm64" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  eval "$(/usr/local/bin/brew shellenv)"
fi

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
[[ ":$PATH:" != *":$PNPM_HOME:"* ]] && export PATH="$PNPM_HOME:$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
[[ ":$PATH:" != *":$BUN_INSTALL/bin:"* ]] && export PATH="$BUN_INSTALL/bin:$PATH"

# Cargo/Rust
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# libpq (PostgreSQL tools)
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

# ══════════════════════════════════════════════════════════════════════════════
# COMPLETIONS SETUP (before zinit, cached compinit)
# ══════════════════════════════════════════════════════════════════════════════

# Add completion paths
fpath=(
  $HOME/.docker/completions
  $fpath
)

# Cached compinit - only regenerate once per day
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# ══════════════════════════════════════════════════════════════════════════════
# ZINIT SETUP
# ══════════════════════════════════════════════════════════════════════════════

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Auto-install zinit if missing
if [[ ! -d "$ZINIT_HOME" ]]; then
  print -P "%F{33}▓▒░ Installing zinit…%f"
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

# ══════════════════════════════════════════════════════════════════════════════
# PLUGINS (via zinit)
# ══════════════════════════════════════════════════════════════════════════════

# Powerlevel10k - load immediately for instant prompt
zinit ice depth=1
zinit light romkatv/powerlevel10k

# fzf-tab - must load after compinit, before other completion plugins
zinit ice wait"0" lucid
zinit light Aloxaf/fzf-tab

# Autosuggestions - load in turbo mode
zinit ice wait"0" lucid atload"_zsh_autosuggest_start"
zinit light zsh-users/zsh-autosuggestions

# Syntax highlighting - must be last plugin
zinit ice wait"0" lucid
zinit light zsh-users/zsh-syntax-highlighting

# ══════════════════════════════════════════════════════════════════════════════
# COMPLETION STYLES
# ══════════════════════════════════════════════════════════════════════════════

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Use menu selection
zstyle ':completion:*' menu select

# Group completions by category
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'

# Colors in completion
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# fzf-tab configuration
zstyle ':fzf-tab:*' fzf-command fzf
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons $realpath 2>/dev/null || lsd -1 --color=always $realpath'
zstyle ':fzf-tab:complete:ls:*' fzf-preview 'eza -1 --color=always --icons $realpath 2>/dev/null || lsd -1 --color=always $realpath'
zstyle ':fzf-tab:*' continuous-trigger '/'

# ══════════════════════════════════════════════════════════════════════════════
# SHELL OPTIONS
# ══════════════════════════════════════════════════════════════════════════════

# History options
setopt EXTENDED_HISTORY          # Write timestamp to history
setopt INC_APPEND_HISTORY        # Write immediately, not on exit
setopt SHARE_HISTORY             # Share history between sessions
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicates first
setopt HIST_IGNORE_DUPS          # Ignore consecutive duplicates
setopt HIST_IGNORE_ALL_DUPS      # Remove older duplicate entries
setopt HIST_FIND_NO_DUPS         # Don't show duplicates in search
setopt HIST_IGNORE_SPACE         # Ignore commands starting with space
setopt HIST_SAVE_NO_DUPS         # Don't save duplicates
setopt HIST_VERIFY               # Show before executing history expansion

# Navigation options
setopt AUTO_CD                   # cd by typing directory name
setopt AUTO_PUSHD                # Push directories onto stack
setopt PUSHD_IGNORE_DUPS         # Don't push duplicates
setopt PUSHD_SILENT              # Don't print stack after pushd/popd

# Globbing & expansion
setopt EXTENDED_GLOB             # Extended globbing (#, ~, ^)
setopt NO_CASE_GLOB              # Case-insensitive globbing
setopt NUMERIC_GLOB_SORT         # Sort numerically when relevant

# Misc
setopt INTERACTIVE_COMMENTS      # Allow comments in interactive shell
setopt NO_BEEP                   # Disable beep
setopt PROMPT_SUBST              # Enable prompt substitution

# ══════════════════════════════════════════════════════════════════════════════
# KEY BINDINGS
# ══════════════════════════════════════════════════════════════════════════════

# Use emacs key bindings
bindkey -e

# Better history search
bindkey '^[[A' history-search-backward  # Up arrow
bindkey '^[[B' history-search-forward   # Down arrow
bindkey '^P' history-search-backward
bindkey '^N' history-search-forward

# Word navigation
bindkey '^[[1;3C' forward-word          # Alt+Right
bindkey '^[[1;3D' backward-word         # Alt+Left
bindkey '^[f' forward-word              # Alt+f
bindkey '^[b' backward-word             # Alt+b

# Delete word
bindkey '^[d' kill-word                 # Alt+d (forward)
bindkey '^W' backward-kill-word         # Ctrl+W (backward)

# Home/End
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line

# Edit command line in $EDITOR (Ctrl+x+e)
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line
bindkey '^xe' edit-command-line

# ══════════════════════════════════════════════════════════════════════════════
# ALIASES (skip for Claude Code - uses standard POSIX tools)
# ══════════════════════════════════════════════════════════════════════════════

[[ -f ~/.zsh_aliases ]] && [[ "$CLAUDECODE" != "1" ]] && source ~/.zsh_aliases

# ══════════════════════════════════════════════════════════════════════════════
# TOOL INTEGRATIONS (after plugins)
# ══════════════════════════════════════════════════════════════════════════════

# direnv (single hook, not double)
(( ${+commands[direnv]} )) && eval "$(direnv hook zsh)"

# fzf - modern integration (0.48+)
source <(fzf --zsh)

# fzf configuration
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix --hidden --follow --exclude .git'

export FZF_DEFAULT_OPTS="
  --height=40%
  --layout=reverse
  --border
  --info=inline
  --color=bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796
  --color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6
  --color=marker:#f4dbd6,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796
  --bind='ctrl-/:toggle-preview'
"

# fzf previews
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || cat {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always --icons {} | head -200'"

# zoxide (smarter cd) - skip for Claude Code (uses __zoxide_z which breaks on unknown dirs)
[[ "$CLAUDECODE" != "1" ]] && eval "$(zoxide init zsh --cmd cd)"

# UV completions (cached)
if [[ ! -f ~/.zsh_uv_completion ]] || [[ ~/.zsh_uv_completion -ot $(which uv) ]]; then
  uv generate-shell-completion zsh > ~/.zsh_uv_completion 2>/dev/null
  uvx --generate-shell-completion zsh >> ~/.zsh_uv_completion 2>/dev/null
fi
[[ -f ~/.zsh_uv_completion ]] && source ~/.zsh_uv_completion

# bun completions
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# atuin (must be last - overrides key bindings)
export ATUIN_PREFERS_REDUCED_MOTION=true
eval "$(atuin init zsh)"

# ══════════════════════════════════════════════════════════════════════════════
# DOTFILES MANAGEMENT (bare git repo)
# ══════════════════════════════════════════════════════════════════════════════

# Manage dotfiles with: config status, config add, config commit, config push
alias dotconfig='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# ══════════════════════════════════════════════════════════════════════════════
# POWERLEVEL10K CONFIG
# ══════════════════════════════════════════════════════════════════════════════

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
