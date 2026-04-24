#!/bin/bash
# Statusline state manager — tracks active agents and tasks via Claude Code hooks.
# Usage: statusline-hooks.sh <action>
# Actions: agent-start  agent-stop  task-create  task-complete  cleanup
# Reads hook-event JSON from stdin.
#
# State files (line-oriented, pipe-delimited):
#   /tmp/claude-sl/{session}-agents  →  id|name|description|timestamp
#   /tmp/claude-sl/{session}-tasks   →  id|description|timestamp

set -f  # disable globbing

ACTION="$1"
INPUT=$(cat)
STATE_DIR="/tmp/claude-sl"
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

# Remove lines matching a pattern from a file; delete file if empty after.
remove_line() {
    local file="$1" pattern="$2"
    [ ! -f "$file" ] && return
    grep -v "$pattern" "$file" > "$file.tmp" 2>/dev/null || true
    mv "$file.tmp" "$file" 2>/dev/null
    [ ! -s "$file" ] && rm -f "$file"
}

# -- Actions ---------------------------------------------------------------
case "$ACTION" in

    agent-start)
        # Parse all fields in one jq call
        eval "$(echo "$INPUT" | jq -r '
            @sh "A_NAME=\(.name // .agent_name // .subagent_type // .tool_input.name // .tool_input.subagent_type // "")",
            @sh "A_DESC=\(.description // .tool_input.description // "")",
            @sh "A_ID=\(.agent_id // .id // .subagent_id // .tool_input.agent_id // .tool_input.id // "")"
        ' 2>/dev/null)" || true
        [ -z "$A_ID" ] && A_ID="a-$(date +%s%N | cut -c1-13)"
        # If no name but has description, promote description to name
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
            remove_line "$AGENTS_FILE" "^${A_ID}|"
        elif [ -n "$A_NAME" ]; then
            remove_line "$AGENTS_FILE" "|${A_NAME}|"
        else
            # Remove oldest entry as fallback
            tail -n +2 "$AGENTS_FILE" > "$AGENTS_FILE.tmp" 2>/dev/null || true
            mv "$AGENTS_FILE.tmp" "$AGENTS_FILE" 2>/dev/null
            [ ! -s "$AGENTS_FILE" ] && rm -f "$AGENTS_FILE"
        fi
        ;;

    task-create)
        eval "$(echo "$INPUT" | jq -r '
            @sh "T_DESC=\(.description // .title // .name // .tool_input.description // .tool_input.title // .tool_input.name // "task")",
            @sh "T_ID=\(.task_id // .id // .tool_input.task_id // .tool_input.id // "")"
        ' 2>/dev/null)" || true
        [ -z "$T_ID" ] && T_ID="t-$(date +%s%N | cut -c1-13)"
        echo "${T_ID}|${T_DESC:0:30}|$(date +%s)" >> "$TASKS_FILE"
        ;;

    task-complete)
        [ ! -f "$TASKS_FILE" ] && exit 0
        eval "$(echo "$INPUT" | jq -r '
            @sh "T_ID=\(.task_id // .id // .tool_input.task_id // .tool_input.id // "")",
            @sh "T_DESC=\(.description // .title // .name // .tool_input.description // .tool_input.title // .tool_input.name // "")"
        ' 2>/dev/null)" || true
        if [ -n "$T_ID" ]; then
            remove_line "$TASKS_FILE" "^${T_ID}|"
        elif [ -n "$T_DESC" ]; then
            remove_line "$TASKS_FILE" "|${T_DESC}|"
        else
            tail -n +2 "$TASKS_FILE" > "$TASKS_FILE.tmp" 2>/dev/null || true
            mv "$TASKS_FILE.tmp" "$TASKS_FILE" 2>/dev/null
            [ ! -s "$TASKS_FILE" ] && rm -f "$TASKS_FILE"
        fi
        ;;

    cleanup)
        rm -f "$AGENTS_FILE" "$TASKS_FILE" 2>/dev/null
        # Purge stale files older than 24 h from any session
        find "$STATE_DIR" \( -name '*-agents' -o -name '*-tasks' \) -mmin +1440 -delete 2>/dev/null
        ;;
esac

exit 0
