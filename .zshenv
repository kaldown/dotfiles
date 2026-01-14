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
  export ENABLE_LSP_TOOL=true
  export CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=true
fi
