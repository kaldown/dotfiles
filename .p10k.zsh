# Powerlevel10k configuration - Lean style with transient prompt
# Generated for optimal performance. Run `p10k configure` to customize.

'builtin' 'local' '-a' 'p10k_config_opts'
[[ ! -o 'aliases'         ]] || p10k_config_opts+=('aliases')
[[ ! -o 'sh_glob'         ]] || p10k_config_opts+=('sh_glob')
[[ ! -o 'no_brace_expand' ]] || p10k_config_opts+=('no_brace_expand')
'builtin' 'setopt' 'no_aliases' 'no_sh_glob' 'brace_expand'

() {
  emulate -L zsh -o extended_glob

  # Unset all configuration options
  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'

  # Zsh >= 5.1 is required
  [[ $ZSH_VERSION == (5.<1->*|<6->.*) ]] || return

  # ════════════════════════════════════════════════════════════════════════════
  # PROMPT SEGMENTS
  # ════════════════════════════════════════════════════════════════════════════

  # Left prompt segments
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    dir                     # Current directory
    vcs                     # Git status
    virtualenv              # Python virtual environment
    prompt_char             # Prompt symbol
  )

  # Right prompt segments
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    status                  # Exit code of last command
    command_execution_time  # Duration of last command
    background_jobs         # Background jobs indicator
    context                 # user@hostname (shows when SSH or root)
  )

  # ════════════════════════════════════════════════════════════════════════════
  # GENERAL SETTINGS
  # ════════════════════════════════════════════════════════════════════════════

  # Mode: 'nerdfont-complete' uses Nerd Font icons
  typeset -g POWERLEVEL9K_MODE=nerdfont-complete

  # Icon padding
  typeset -g POWERLEVEL9K_ICON_PADDING=moderate

  # Prompt on same line as command
  typeset -g POWERLEVEL9K_PROMPT_ON_NEWLINE=false

  # Add newline before each prompt
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=false

  # Transient prompt: simplify past prompts to just the prompt char
  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=same-dir

  # Instant prompt mode: verbose shows warnings, quiet hides them
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

  # ════════════════════════════════════════════════════════════════════════════
  # DIRECTORY
  # ════════════════════════════════════════════════════════════════════════════

  typeset -g POWERLEVEL9K_DIR_FOREGROUND=31      # Blue

  # Shorten directory path
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
  typeset -g POWERLEVEL9K_SHORTEN_DELIMITER=
  typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=103

  # Directory anchors (never truncate these)
  typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true
  local anchor_files=(
    .git
    .node-version
    .python-version
    .ruby-version
    .go-version
    .tool-versions
    Cargo.toml
    go.mod
    package.json
    pyproject.toml
    setup.py
    requirements.txt
  )
  typeset -g POWERLEVEL9K_SHORTEN_FOLDER_MARKER="(${(j:|:)anchor_files})"

  # Truncate to last 3 directories
  typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=3

  # ════════════════════════════════════════════════════════════════════════════
  # VCS (Git)
  # ════════════════════════════════════════════════════════════════════════════

  # Enable git status
  typeset -g POWERLEVEL9K_VCS_DISABLED_WORKDIR_PATTERN='~'

  # Branch icon
  typeset -g POWERLEVEL9K_VCS_BRANCH_ICON='\uF126 '

  # Colors
  typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=76       # Green
  typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=178   # Yellow
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=178  # Yellow

  # Git status formatting
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_ICON='?'
  typeset -g POWERLEVEL9K_VCS_UNSTAGED_ICON='!'
  typeset -g POWERLEVEL9K_VCS_STAGED_ICON='+'
  typeset -g POWERLEVEL9K_VCS_STASH_ICON='*'
  typeset -g POWERLEVEL9K_VCS_INCOMING_CHANGES_ICON='⇣'
  typeset -g POWERLEVEL9K_VCS_OUTGOING_CHANGES_ICON='⇡'

  # Commit hash (show short hash)
  typeset -g POWERLEVEL9K_VCS_COMMIT_ICON='@'

  # ════════════════════════════════════════════════════════════════════════════
  # PROMPT CHAR
  # ════════════════════════════════════════════════════════════════════════════

  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=76      # Green
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=196  # Red

  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='❯'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='❮'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIVIS_CONTENT_EXPANSION='V'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIOWR_CONTENT_EXPANSION='▶'

  typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=true

  # ════════════════════════════════════════════════════════════════════════════
  # STATUS (Exit Code)
  # ════════════════════════════════════════════════════════════════════════════

  typeset -g POWERLEVEL9K_STATUS_OK=false                    # Don't show on success
  typeset -g POWERLEVEL9K_STATUS_ERROR=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=196        # Red

  # ════════════════════════════════════════════════════════════════════════════
  # COMMAND EXECUTION TIME
  # ════════════════════════════════════════════════════════════════════════════

  # Show if command took longer than 3 seconds
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=101  # Muted
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=0

  # ════════════════════════════════════════════════════════════════════════════
  # BACKGROUND JOBS
  # ════════════════════════════════════════════════════════════════════════════

  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=37
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_ICON='⚙'

  # ════════════════════════════════════════════════════════════════════════════
  # CONTEXT (user@host)
  # ════════════════════════════════════════════════════════════════════════════

  # Only show when SSH or root
  typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO}_CONTENT_EXPANSION=
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_FOREGROUND=178
  typeset -g POWERLEVEL9K_CONTEXT_{REMOTE,REMOTE_SUDO}_FOREGROUND=180
  typeset -g POWERLEVEL9K_CONTEXT_{ROOT,REMOTE,REMOTE_SUDO}_CONTENT_EXPANSION='%n@%m'

  # ════════════════════════════════════════════════════════════════════════════
  # PYTHON VIRTUAL ENVIRONMENT
  # ════════════════════════════════════════════════════════════════════════════

  typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=37
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=false
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_WITH_PYENV=false
  typeset -g POWERLEVEL9K_VIRTUALENV_{LEFT,RIGHT}_DELIMITER=

  # ════════════════════════════════════════════════════════════════════════════
  # HOT RELOAD
  # ════════════════════════════════════════════════════════════════════════════

  # Allow hot reload of this config: `source ~/.p10k.zsh`
  (( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
  'builtin' 'unset' 'p10k_config_opts'
}

# Tell Powerlevel10k not to show prompt configuration wizard
typeset -g POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
