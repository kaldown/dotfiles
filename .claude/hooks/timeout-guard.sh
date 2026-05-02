#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# timeout-guard.sh — Claude Code PreToolUse hook
# ──────────────────────────────────────────────────────────────────────────────
# WHY IT EXISTS
#   Sub-agents that fire `pytest`/`playwright`/etc. with sandbox disabled can
#   wedge a parent Claude session for hours when BASH_DEFAULT_TIMEOUT_MS fails
#   to fire. This hook prevents that at the source: it inspects every Bash
#   command Claude is about to run and rejects the hang-prone ones unless they
#   are wrapped in a timeout. It also logs *every* tool call (any kind, every
#   session, every sub-agent) so you can `tail -f` what Claude is doing.
#
# INSTALL
#   1. Place this file at ~/.claude/hooks/timeout-guard.sh and `chmod +x`.
#   2. In ~/.claude/settings.json, add to the `"hooks"` block:
#        "PreToolUse": [{ "hooks": [{ "type": "command",
#          "command": "bash ~/.claude/hooks/timeout-guard.sh" }]}]
#   3. Restart any open Claude sessions (existing sessions cache settings).
#
# USE / TEST
#   tail -f ~/.claude/tool-calls.log               # live tool-call feed
#   echo '{"tool_name":"Bash","tool_input":{"command":"pytest"}}' \
#     | bash ~/.claude/hooks/timeout-guard.sh ; echo "rc=$?"   # expect rc=2
#
# BYPASS one command (use sparingly):
#   include the literal token TIMEOUT_GUARD_OFF=1 in the command, e.g.
#     TIMEOUT_GUARD_OFF=1 uv run pytest tests/test_slow.py
#
# DISABLE permanently
#   Remove the .hooks.PreToolUse block from ~/.claude/settings.json. The
#   script can stay in place; it only runs if settings.json points at it.
#
# RUNTIME TUNABLES (env vars read at hook invocation)
#   CLAUDE_TOOL_LOG            log file path        (default ~/.claude/tool-calls.log)
#   CLAUDE_HANG_GUARD_TIMEOUT  seconds quoted in the block message (default 120)
#
# RELATED
#   ~/.claude/hooks/hang-watchdog.sh + LaunchAgents plist — OS-level safety
#   net that kills hang-prone processes that slipped past this hook
#   (e.g., from older sessions started before this hook was installed).
# ──────────────────────────────────────────────────────────────────────────────
set -u

LOG="${CLAUDE_TOOL_LOG:-$HOME/.claude/tool-calls.log}"
TO="${CLAUDE_HANG_GUARD_TIMEOUT:-120}"

input="$(cat)"
parsed=$(jq -r '[.tool_name, (.session_id // ""), (.tool_input.command // ""), (.tool_input.description // "")] | @tsv' <<<"$input")
IFS=$'\t' read -r tool sess cmd desc <<<"$parsed"

ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf '%s | %s | %s | %s | %s\n' "$ts" "${sess:0:8}" "$tool" "${desc:0:60}" "${cmd:0:240}" >> "$LOG"

if [[ "$tool" != "Bash" ]]; then exit 0; fi
if [[ "$cmd" == *"TIMEOUT_GUARD_OFF=1"* ]]; then exit 0; fi

hang='(^|[ /])(pytest|playwright|jest)( |$|[<>;|&])'
wrap='(gtimeout|timeout)'

hit_hang=0
hit_wrap=0
[[ "$cmd" =~ $hang ]] && hit_hang=1
[[ "$cmd" =~ $wrap ]] && hit_wrap=1

if (( hit_hang == 1 && hit_wrap == 0 )); then
  >&2 echo "BLOCKED by timeout-guard: hang-prone command (pytest/playwright/jest) without timeout wrapper. Re-run as: gtimeout ${TO} <your command>. Bypass: prefix the command with TIMEOUT_GUARD_OFF=1."
  exit 2
fi

exit 0
