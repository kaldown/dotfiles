#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# hang-watchdog.sh — OS-level safety net for hung Claude Code subagents
# ──────────────────────────────────────────────────────────────────────────────
# WHY IT EXISTS
#   The Claude-side timeout-guard hook prevents NEW hang-prone Bash commands
#   from running. This script catches the ones that slipped past it:
#   processes already running before the hook was installed, commands that
#   used dangerouslyDisableSandbox=true and ignored BASH_DEFAULT_TIMEOUT_MS,
#   etc. It scans /bin/ps and SIGKILLs any pytest/playwright process older
#   than MAX_AGE seconds.
#
# INSTALL
#   1. Place this file at ~/.claude/hooks/hang-watchdog.sh and `chmod +x`.
#   2. Place the launchd plist at
#        ~/Library/LaunchAgents/local.claude-hang-watchdog.plist
#      The plist invokes this script through /bin/sh so $HOME expands at
#      runtime — no hard-coded /Users/<name>/ paths needed.
#   3. launchctl load ~/Library/LaunchAgents/local.claude-hang-watchdog.plist
#   The plist invokes this script with `--once` every 30s (StartInterval) and
#   once at login (RunAtLoad).
#
# RUN MODES
#   bash ~/.claude/hooks/hang-watchdog.sh --once   # single scan (used by launchd)
#   bash ~/.claude/hooks/hang-watchdog.sh          # continuous loop (manual debug)
#
# CHECK / DEBUG
#   launchctl list | grep local.claude-hang-watchdog   # is it registered?
#   tail -f ~/.claude/watchdog.log                     # what has it killed?
#   CLAUDE_WATCHDOG_MAX_AGE=5 bash ~/.claude/hooks/hang-watchdog.sh --once
#       # (lower threshold for ad-hoc testing without waiting 3 min)
#
# DISABLE temporarily / permanently
#   launchctl unload ~/Library/LaunchAgents/local.claude-hang-watchdog.plist
#   then `rm` both this script and the plist if removing for good.
#
# RUNTIME TUNABLES (env vars)
#   CLAUDE_WATCHDOG_MAX_AGE    seconds before kill        (default 180)
#   CLAUDE_WATCHDOG_INTERVAL   loop sleep when not --once (default 30)
#   CLAUDE_WATCHDOG_LOG        kill-log path              (default ~/.claude/watchdog.log)
#
# PAIR
#   ~/.claude/hooks/timeout-guard.sh — Claude-side prevention (PreToolUse hook).
# ──────────────────────────────────────────────────────────────────────────────
MAX="${CLAUDE_WATCHDOG_MAX_AGE:-180}"
INT="${CLAUDE_WATCHDOG_INTERVAL:-30}"
LOG="${CLAUDE_WATCHDOG_LOG:-$HOME/.claude/watchdog.log}"
PAT='(pytest|playwright)'

to_secs() {
  local t="$1" d=0 h=0 m=0 s=0
  [[ "$t" == *-* ]] && { d="${t%%-*}"; t="${t#*-}"; }
  IFS=: read -ra p <<<"$t"
  case ${#p[@]} in
    3) h="${p[0]}"; m="${p[1]}"; s="${p[2]}";;
    2) m="${p[0]}"; s="${p[1]}";;
  esac
  echo $((10#${d:-0}*86400 + 10#${h:-0}*3600 + 10#${m:-0}*60 + 10#${s:-0}))
}

run_once() {
  /bin/ps -axwwo pid=,etime=,command= | while read -r pid etime rest; do
    [[ -z "$rest" || "$rest" == *grep* || "$rest" == *watchdog* ]] && continue
    [[ "$rest" =~ $PAT ]] || continue
    secs=$(to_secs "$etime")
    if (( secs > MAX )); then
      printf '%s KILL pid=%s age=%ss cmd=%s\n' "$(date -Is)" "$pid" "$secs" "${rest:0:140}" >> "$LOG"
      kill -TERM "$pid" 2>/dev/null
      sleep 3
      kill -KILL "$pid" 2>/dev/null
    fi
  done
}

if [[ "${1:-}" == "--once" ]]; then
  run_once
  exit 0
fi

while :; do
  run_once
  sleep "$INT"
done
