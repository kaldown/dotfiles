export PATH="$HOME/.local/bin:$PATH"
#export PATH="$PATH:$(go env GOPATH)/bin"
export PATH="$PATH:$HOME/go/bin"
export PATH="/opt/homebrew/opt/python/libexec/bin:$PATH"

# ══════════════════════════════════════════════════════════════════════════════
# CLAUDE CODE ENVIRONMENT OVERRIDES
# ══════════════════════════════════════════════════════════════════════════════

# Docker buildx state directory - use /tmp/claude to avoid permission issues
# with ~/.docker/buildx/activity/ that occur due to macOS extended attributes
if [[ "$CLAUDECODE" == "1" ]]; then
  export BUILDX_CONFIG=/tmp/claude/buildx-config
  export ENABLE_LSP_TOOL="1"
  #export CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=true
  export TMPPREFIX=/tmp/claude/zsh
  # Use project-local uv cache to work within Claude Code sandbox
  export UV_CACHE_DIR="${PWD}/.uv-cache"
  # Skip network checks to avoid sandbox blocking macOS system APIs
  export UV_OFFLINE="1"
  #export CLAUDE_CODE_TMPDIR=/tmp/claude
  # Usa experimental multi-agent approach
  export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS="1"
fi

