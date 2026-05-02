#!/bin/bash
# Statusline state manager — tracks active agents and tasks via Claude Code hooks.
# Usage: statusline-hooks.sh <action>
# Actions: agent-start  agent-stop  task-create  task-complete  cleanup
# Reads hook-event JSON from stdin.
#
# State files (line-oriented, pipe-delimited):
#   $STATE_DIR/{session}-agents  →  id|name|description|timestamp
#   $STATE_DIR/{session}-tasks   →  id|description|timestamp

set -f  # disable globbing

ACTION="$1"
INPUT=$(cat)
STATE_DIR="${TMPDIR:-/tmp}/claude-sl"
mkdir -p "$STATE_DIR"

# -- Debug log (rotate at 50 KB) ------------------------------------------
DEBUG_LOG="$STATE_DIR/debug.log"
[ -f "$DEBUG_LOG" ] && [ "$(stat -f%z "$DEBUG_LOG" 2>/dev/null || echo 0)" -gt 51200 ] && \
    tail -20 "$DEBUG_LOG" > "$DEBUG_LOG.tmp" && mv "$DEBUG_LOG.tmp" "$DEBUG_LOG"
echo "$(date '+%H:%M:%S') $ACTION: $INPUT" >> "$DEBUG_LOG" 2>/dev/null

# -- Extract session ID (always present) -----------------------------------
SID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
[ -z "$SID" ] && exit 0

AGENTS_FILE="$STATE_DIR/${SID}-agents"
TASKS_FILE="$STATE_DIR/${SID}-tasks"

# -- Helpers ---------------------------------------------------------------

# Generate a unique ID (macOS date lacks %N)
_uid() { printf '%s-%s' "$(date +%s)" "$(head -c4 /dev/urandom | od -An -tx4 | tr -d ' ')"; }

# Remove line from file by matching a specific pipe-delimited field.
# Usage: remove_by_field <file> <field_num> <value>
remove_by_field() {
    local file="$1" fnum="$2" val="$3"
    [ ! -f "$file" ] && return
    awk -F'|' -v f="$fnum" -v v="$val" '$(f) != v' "$file" > "$file.tmp" 2>/dev/null || true
    mv "$file.tmp" "$file" 2>/dev/null
    [ ! -s "$file" ] && rm -f "$file"
}

# Remove oldest line from file.
remove_oldest() {
    local file="$1"
    [ ! -f "$file" ] && return
    tail -n +2 "$file" > "$file.tmp" 2>/dev/null || true
    mv "$file.tmp" "$file" 2>/dev/null
    [ ! -s "$file" ] && rm -f "$file"
}

# -- Actions ---------------------------------------------------------------
case "$ACTION" in

    agent-start)
        eval "$(echo "$INPUT" | jq -r '
            @sh "A_NAME=\(.name // .agent_name // .subagent_type // .tool_input.name // .tool_input.subagent_type // "")",
            @sh "A_DESC=\(.description // .tool_input.description // "")",
            @sh "A_ID=\(.agent_id // .id // .subagent_id // .tool_input.agent_id // .tool_input.id // "")"
        ' 2>/dev/null)" || true
        [ -z "$A_ID" ] && A_ID="a-$(_uid)"
        [ -z "$A_NAME" ] && A_NAME="${A_DESC:-agent}" && A_DESC=""
        echo "${A_ID}|${A_NAME:0:25}|${A_DESC:0:40}|$(date +%s)" >> "$AGENTS_FILE"
        ;;

    agent-stop)
        [ ! -f "$AGENTS_FILE" ] && exit 0
        eval "$(echo "$INPUT" | jq -r '
            @sh "A_ID=\(.agent_id // .id // .subagent_id // .tool_input.agent_id // .tool_input.id // "")",
            @sh "A_NAME=\(.name // .description // .agent_name // .subagent_type // .tool_input.name // .tool_input.description // .tool_input.subagent_type // "")"
        ' 2>/dev/null)" || true
        if [ -n "$A_ID" ]; then
            remove_by_field "$AGENTS_FILE" 1 "$A_ID"
        elif [ -n "$A_NAME" ]; then
            remove_by_field "$AGENTS_FILE" 2 "$A_NAME"
        else
            remove_oldest "$AGENTS_FILE"
        fi
        ;;

    task-create)
        eval "$(echo "$INPUT" | jq -r '
            @sh "T_DESC=\(.description // .title // .name // .tool_input.description // .tool_input.title // .tool_input.name // "task")",
            @sh "T_ID=\(.task_id // .id // .tool_input.task_id // .tool_input.id // "")"
        ' 2>/dev/null)" || true
        [ -z "$T_ID" ] && T_ID="t-$(_uid)"
        echo "${T_ID}|${T_DESC:0:30}|$(date +%s)" >> "$TASKS_FILE"
        ;;

    task-complete)
        [ ! -f "$TASKS_FILE" ] && exit 0
        eval "$(echo "$INPUT" | jq -r '
            @sh "T_ID=\(.task_id // .id // .tool_input.task_id // .tool_input.id // "")",
            @sh "T_DESC=\(.description // .title // .name // .tool_input.description // .tool_input.title // .tool_input.name // "")"
        ' 2>/dev/null)" || true
        if [ -n "$T_ID" ]; then
            remove_by_field "$TASKS_FILE" 1 "$T_ID"
        elif [ -n "$T_DESC" ]; then
            remove_by_field "$TASKS_FILE" 2 "$T_DESC"
        else
            remove_oldest "$TASKS_FILE"
        fi
        ;;

    cleanup)
        # Only remove this session's files — never touch other sessions
        rm -f "$AGENTS_FILE" "$TASKS_FILE" 2>/dev/null
        ;;
esac

exit 0
