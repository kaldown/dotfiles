#!/bin/zsh
#
# Claude Code Security Hooks Injector
# Ensures hookify rules exist before Claude starts
#
# What it does:
#   1. Checks templates exist in ~/.claude/templates/
#   2. Creates .claude/ in current directory if missing
#   3. Copies templates with {{PROJECT_DIR}} replaced by $PWD
#
# Usage (in ~/.zsh_aliases):
#   alias claude='~/.claude/scripts/claude-wrapper.sh && command claude'
#
# Templates: ~/.claude/templates/hookify.*.local.md
# Output:    ./.claude/hookify.*.local.md
#

set -euo pipefail

TEMPLATE_DIR="${HOME}/.claude/templates"
LOCAL_CLAUDE_DIR=".claude"
REQUIRED_HOOKS=(
    "hookify.block-external-bash-ops.local.md"
    "hookify.block-external-file-ops.local.md"
)

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_ok() { echo -e "${GREEN}[claude]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[claude]${NC} $1"; }
log_err() { echo -e "${RED}[claude]${NC} $1"; }

# Check templates exist
if [[ ! -d "$TEMPLATE_DIR" ]]; then
    log_err "Templates not found: $TEMPLATE_DIR"
    log_err "Run: mkdir -p ~/.claude/templates && copy hook templates there"
    exit 1
fi

# Create .claude if needed
[[ ! -d "$LOCAL_CLAUDE_DIR" ]] && mkdir -p "$LOCAL_CLAUDE_DIR"

# Inject missing hooks
for hook in "${REQUIRED_HOOKS[@]}"; do
    local_file="$LOCAL_CLAUDE_DIR/$hook"
    template_file="$TEMPLATE_DIR/$hook"

    if [[ ! -f "$template_file" ]]; then
        log_warn "Missing template: $hook"
        continue
    fi

    if [[ ! -f "$local_file" ]]; then
        # Replace {{PROJECT_DIR}} with current directory
        sed "s|{{PROJECT_DIR}}|$PWD|g" "$template_file" > "$local_file"
        log_ok "Injected: $hook"
    fi
done

# Done - hooks injected, ready for claude
log_ok "Security hooks ready"

