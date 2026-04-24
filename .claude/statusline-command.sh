#!/bin/bash
# Status line for Claude Code — Powerlevel10k inspired
# Reads session JSON from stdin, outputs colored multi-line status.
# Line 1: user@host:dir [model] [effort] [ctx] [cost] [duration] [session]
# Line 2+: active agents (from hook state files)
# Line 3+: active tasks  (from hook state files)
#
# Artifacts: all temp files live under $STATE_DIR (cleaned on Stop hook).

set -f

# -- Colors & helpers ------------------------------------------------------
CYAN='\033[0;36m'  BLUE='\033[0;34m'  YELLOW='\033[0;33m'
RED='\033[0;31m'   GREEN='\033[0;32m' MAGENTA='\033[0;35m'
DIM='\033[2m'      RESET='\033[0m'

badge() { printf '%b[%b%s%b%b]%b' "$DIM" "$1" "$2" "$RESET" "$DIM" "$RESET"; }

fmt_elapsed() {
    local ts="$1"
    [ -z "$ts" ] || [ "$ts" -le 0 ] 2>/dev/null && return
    local s=$(( now - ts ))
    if [ "$s" -ge 60 ]; then printf ' %b%dm%ds%b' "$DIM" $((s/60)) $((s%60)) "$RESET"
    else                     printf ' %b%ds%b' "$DIM" "$s" "$RESET"
    fi
}

# Render a 10-cell progress bar for context used %.
# Color is keyed on REMAINING %: <20 red, 20-49 yellow, ≥50 cyan.
ctx_bar() {
    local pct="$1"
    [ -z "$pct" ] || [ "$pct" -le 0 ] 2>/dev/null && return
    [ "$pct" -gt 100 ] 2>/dev/null && pct=100
    local filled=$(( pct / 10 ))
    local empty=$(( 10 - filled ))
    local bar=""
    local i=0
    while [ "$i" -lt "$filled" ]; do bar="${bar}▓"; i=$((i+1)); done
    i=0
    while [ "$i" -lt "$empty" ];  do bar="${bar}░"; i=$((i+1)); done
    local remain=$(( 100 - pct ))
    local color
    if   [ "$remain" -lt 20 ]; then color="$RED"
    elif [ "$remain" -lt 50 ]; then color="$YELLOW"
    else                            color="$CYAN"
    fi
    printf '%bctx %s %d%%%b' "$color" "$bar" "$pct" "$RESET"
}

# Return "branch±N" (dirty) or "branch" (clean) for the given cwd, or empty
# if the cwd isn't inside a git repo. Result is cached 3s per-cwd.
git_info() {
    local cwd="$1"
    [ -z "$cwd" ] && return
    # md5 on macOS (BSD: md5 -qs), fall back to md5sum on Linux.
    local hash
    hash=$(md5 -qs "$cwd" 2>/dev/null || printf '%s' "$cwd" | md5sum 2>/dev/null | cut -d' ' -f1)
    local cache="$STATE_DIR/git-$hash"
    local now_s; now_s=$(date +%s)
    if [ -f "$cache" ]; then
        local mtime
        mtime=$(stat -f%m "$cache" 2>/dev/null || stat -c%Y "$cache" 2>/dev/null || echo 0)
        if [ $(( now_s - mtime )) -lt 3 ]; then cat "$cache"; return; fi
    fi
    local branch
    branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null) || {
        : > "$cache"
        return
    }
    local dirty
    dirty=$(git -C "$cwd" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    local out
    if [ "${dirty:-0}" -gt 0 ] 2>/dev/null; then
        out=$(printf '%b%s±%s%b' "$YELLOW" "$branch" "$dirty" "$RESET")
    else
        out=$(printf '%b%s%b' "$DIM" "$branch" "$RESET")
    fi
    printf '%s' "$out" > "$cache"
    printf '%s' "$out"
}

# -- Read JSON from stdin --------------------------------------------------
INPUT=$(cat)
[ -z "$INPUT" ] && { echo "Claude"; exit 0; }

# -- Parse all fields in a single jq call ----------------------------------
eval "$(echo "$INPUT" | jq -r '
  @sh "MODEL=\(.model.display_name // "Claude")",
  @sh "MODEL_ID=\(.model.id // "")",
  @sh "SESSION_ID=\(.session_id // "")",
  @sh "CWD=\(.cwd // "")",
  @sh "PCT=\(.context_window.used_percentage // 0)",
  @sh "OUTPUT_STYLE=\(.output_style.name // "default")"
' 2>/dev/null)" || true

PCT="${PCT%%.*}"
now=$(date +%s)
STATE_DIR="${TMPDIR:-/tmp}/claude-sl"

mkdir -p "$STATE_DIR"

# -- Directory with ~ substitution ----------------------------------------
CWD="${CWD:-$PWD}"
DIR="${BLUE}${CWD/#$HOME/\~}${RESET}"

# -- Effort level (env > project settings > user settings) -----------------
EFFORT=""
if [ -n "$CLAUDE_CODE_EFFORT_LEVEL" ]; then
    EFFORT="$CLAUDE_CODE_EFFORT_LEVEL"
else
    for p in "$CWD/.claude/settings.json" "$HOME/.claude/settings.json"; do
        [ -f "$p" ] && val=$(jq -r '.effortLevel // empty' "$p" 2>/dev/null) && [ -n "$val" ] && { EFFORT="$val"; break; }
    done
fi

case "$EFFORT" in
    low)    EFF_COLOR="$RED"     ;;
    medium) EFF_COLOR="$YELLOW"  ;;
    high)   EFF_COLOR="$GREEN"   ;;
    max)    EFF_COLOR="$MAGENTA" ;;
    *)      EFF_COLOR="$CYAN"    ;;
esac

MODEL_INFO="$(badge "$MAGENTA" "$MODEL")"
[ -n "$EFFORT" ] && MODEL_INFO="$MODEL_INFO $(badge "$EFF_COLOR" "$EFFORT")"

# -- Context progress bar --------------------------------------------------
CTX=""
if [ "${PCT:-0}" -gt 0 ] 2>/dev/null; then
    CTX="  $(ctx_bar "$PCT")"
fi



# -- Output style (non-default only) --------------------------------------
STYLE=""
[ -n "$OUTPUT_STYLE" ] && [ "$OUTPUT_STYLE" != "default" ] && \
    STYLE=" $(badge "$CYAN" "$OUTPUT_STYLE")"


# -- Active agents (from hook state files) ---------------------------------
AGENT_LINES=""
AGENTS_FILE="$STATE_DIR/${SESSION_ID}-agents"

if [ -n "$SESSION_ID" ] && [ -f "$AGENTS_FILE" ] && [ -s "$AGENTS_FILE" ]; then
    while IFS='|' read -r _id aname adesc ats; do
        [ -z "$aname" ] && continue
        elapsed=$(fmt_elapsed "$ats")
        if [ -n "$adesc" ]; then
            AGENT_LINES="${AGENT_LINES}\n ${MAGENTA}>${RESET} ${MAGENTA}${aname}${RESET}${DIM}:${RESET} ${adesc}${elapsed}"
        else
            AGENT_LINES="${AGENT_LINES}\n ${MAGENTA}>${RESET} ${MAGENTA}${aname}${RESET}${elapsed}"
        fi
    done < "$AGENTS_FILE"
fi

# -- Active tasks (from hook state files) ----------------------------------
TASK_LINES=""
TASKS_FILE="$STATE_DIR/${SESSION_ID}-tasks"

if [ -n "$SESSION_ID" ] && [ -f "$TASKS_FILE" ] && [ -s "$TASKS_FILE" ]; then
    while IFS='|' read -r _id tdesc tts; do
        [ -z "$tdesc" ] && continue
        elapsed=$(fmt_elapsed "$tts")
        TASK_LINES="${TASK_LINES}\n ${CYAN}>${RESET} ${tdesc}${elapsed}"
    done < "$TASKS_FILE"
fi

# -- Output ----------------------------------------------------------------
GIT=$(git_info "$CWD")
[ -n "$GIT" ] && GIT="  $GIT"
echo -e "${DIR}${GIT}  ${MODEL_INFO}${STYLE}${CTX}"
[ -n "$AGENT_LINES" ] && echo -e "$AGENT_LINES"
[ -n "$TASK_LINES" ]  && echo -e "$TASK_LINES"

exit 0
