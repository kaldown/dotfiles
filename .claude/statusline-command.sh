#!/bin/bash

# Status line script for Claude Code - Powerlevel10k inspired
# Reads JSON from stdin

# Colors (ANSI)
CYAN='\033[0;36m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
MAGENTA='\033[0;35m'
RESET='\033[0m'
DIM='\033[2m'

# Read JSON from stdin
INPUT=$(cat)

# Parse JSON fields
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
CONTEXT_SIZE=$(echo "$INPUT" | jq -r '.context_window.context_window_size // 0')
CURRENT_INPUT=$(echo "$INPUT" | jq -r '.context_window.current_usage.input_tokens // 0')
CACHE_CREATE=$(echo "$INPUT" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
CACHE_READ=$(echo "$INPUT" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')

# User and hostname
USER_HOST="${CYAN}$(whoami)@$(hostname -s)${RESET}"

# Current directory with ~ substitution
if [ -n "$CWD" ]; then
    DIR="${BLUE}${CWD/#$HOME/~}${RESET}"
else
    DIR="${BLUE}${PWD/#$HOME/~}${RESET}"
fi

# Git info
GIT_INFO=""
if git rev-parse --is-inside-work-tree &>/dev/null; then
    BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    if [ -n "$BRANCH" ]; then
        # Check for uncommitted changes
        if git diff --quiet 2>/dev/null && git diff --cached --quiet 2>/dev/null; then
            GIT_INFO=" ${YELLOW}${BRANCH}${RESET}"
        else
            GIT_INFO=" ${RED}${BRANCH}*${RESET}"
        fi
    fi
fi

# Fast mode and effort level from settings/env
SETTINGS_FILE="$HOME/.claude/settings.json"
FAST_ENABLED="false"
EFFORT_SETTING="high"

if [ -f "$SETTINGS_FILE" ]; then
    FAST_ENABLED=$(jq -r '.fastMode // false' "$SETTINGS_FILE" 2>/dev/null)
    EFFORT_FROM_SETTINGS=$(jq -r '.effortLevel // empty' "$SETTINGS_FILE" 2>/dev/null)
    [ -n "$EFFORT_FROM_SETTINGS" ] && EFFORT_SETTING="$EFFORT_FROM_SETTINGS"
fi

# Env var overrides settings for effort
[ -n "$CLAUDE_CODE_EFFORT_LEVEL" ] && EFFORT_SETTING="$CLAUDE_CODE_EFFORT_LEVEL"

# Build effort indicator (always shown)
case "$EFFORT_SETTING" in
    low)    EFFORT_INFO="${DIM}[${RED}effort:low${RESET}${DIM}]${RESET}" ;;
    medium) EFFORT_INFO="${DIM}[${YELLOW}effort:med${RESET}${DIM}]${RESET}" ;;
    *)      EFFORT_INFO="${DIM}[${GREEN}effort:high${RESET}${DIM}]${RESET}" ;;
esac

# Speed indicator: lightning for fast, turtle for standard
if [ "$FAST_ENABLED" = "true" ]; then
    SPEED_ICON="${YELLOW}↯${RESET}"
else
    SPEED_ICON="🐢"
fi

# Model name with speed and effort
MODEL_INFO=""
if [ -n "$MODEL" ]; then
    MODEL_INFO=" ${DIM}[${MAGENTA}${MODEL}${RESET} ${SPEED_ICON}${DIM}]${RESET} ${EFFORT_INFO}"
fi

# Context remaining percentage
CTX_INFO=""
if [ "$CONTEXT_SIZE" -gt 0 ] 2>/dev/null; then
    CURRENT_TOKENS=$((CURRENT_INPUT + CACHE_CREATE + CACHE_READ))
    PERCENT_USED=$((CURRENT_TOKENS * 100 / CONTEXT_SIZE))
    PERCENT_LEFT=$((100 - PERCENT_USED))

    if [ "$PERCENT_LEFT" -lt 20 ]; then
        CTX_INFO=" ${DIM}[ctx:${RED}${PERCENT_LEFT}%${RESET}${DIM}]${RESET}"
    else
        CTX_INFO=" ${DIM}[ctx:${CYAN}${PERCENT_LEFT}%${RESET}${DIM}]${RESET}"
    fi
fi

# Session ID (full, for cross-session resume)
SESSION_INFO=""
if [ -n "$SESSION_ID" ]; then
    SESSION_INFO=" ${DIM}[sid:${CYAN}${SESSION_ID}${RESET}${DIM}]${RESET}"
fi

echo -e "${USER_HOST}:${DIR}${GIT_INFO}${MODEL_INFO}${CTX_INFO}${SESSION_INFO}"
