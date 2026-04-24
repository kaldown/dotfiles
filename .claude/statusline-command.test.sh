#!/bin/bash
# Regression tests for statusline-command.sh
# Each fixture pipes canned JSON into the script and greps the output.
# Run: bash ~/.claude/statusline-command.test.sh

set -u
SCRIPT="$(cd "$(dirname "$0")" && pwd)/statusline-command.sh"

# Isolate state dir so the harness never touches real session state.
TEST_STATE_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_STATE_DIR"' EXIT
export TMPDIR="$TEST_STATE_DIR/"

PASS=0
FAIL=0
CURRENT_LABEL=""

fail() { printf 'FAIL [%s]: %s\n' "$CURRENT_LABEL" "$1"; FAIL=$((FAIL+1)); }
pass() { PASS=$((PASS+1)); }

# Strip ANSI escapes so grep works on raw text.
strip_ansi() { sed $'s/\033\\[[0-9;]*m//g'; }

assert_contains() {
    local output="$1" needle="$2" msg="$3"
    if printf '%s' "$output" | strip_ansi | grep -qF -- "$needle"; then
        pass
    else
        fail "$msg — expected to contain '$needle'; got: $(printf '%s' "$output" | strip_ansi)"
    fi
}

assert_missing() {
    local output="$1" needle="$2" msg="$3"
    if printf '%s' "$output" | strip_ansi | grep -qF -- "$needle"; then
        fail "$msg — should not contain '$needle'; got: $(printf '%s' "$output" | strip_ansi)"
    else
        pass
    fi
}

run_with() {
    printf '%s' "$1" | bash "$SCRIPT"
}

# -----------------------------------------------------------------------------
# Fixtures added by later tasks.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Fixture 1: baseline payload (no rate_limits, no current_usage, no 1M flag)
# Asserts that Task 2's deletions actually removed the old segments.
# -----------------------------------------------------------------------------
CURRENT_LABEL="baseline"
BASELINE_JSON='{"session_id":"abc12345-6789-0000-0000-000000000000","cwd":"/tmp","model":{"id":"claude-opus-4-7","display_name":"Opus"},"context_window":{"used_percentage":22},"cost":{"total_cost_usd":0.42,"total_duration_ms":120000},"output_style":{"name":"default"}}'
OUT=$(run_with "$BASELINE_JSON")
assert_contains "$OUT" "Opus"       "model visible"
assert_contains "$OUT" "ctx"        "ctx label visible (exact format asserted in Task 3)"
assert_missing  "$OUT" "0.42"       "cost removed"
assert_missing  "$OUT" "\$0"        "no dollar-cost token"
assert_missing  "$OUT" "2m0s"       "duration removed"
assert_missing  "$OUT" "abc12345"   "session-id removed"
assert_missing  "$OUT" "@"          "user@host removed"
assert_contains "$OUT" "ctx"        "ctx label present"
assert_contains "$OUT" "░"          "ctx bar empty cell present"
assert_contains "$OUT" "22%"        "ctx pct present"

CURRENT_LABEL="ctx_bar_66"
CTX66_JSON='{"session_id":"s","cwd":"/tmp","model":{"id":"claude-opus-4-7","display_name":"Opus"},"context_window":{"used_percentage":66}}'
OUT=$(run_with "$CTX66_JSON")
assert_contains "$OUT" "▓▓▓▓▓▓░░░░" "66% → 6 filled, 4 empty"
assert_contains "$OUT" "66%"         "66% label present"

# -----------------------------------------------------------------------------
# Fixture 3: git dirty state — build a tmp repo, stage nothing, modify one file.
# -----------------------------------------------------------------------------
CURRENT_LABEL="git_dirty"
GIT_TMP=$(mktemp -d)
(
    cd "$GIT_TMP"
    git init -q -b main
    git config user.email "t@t"
    git config user.name  "t"
    echo a > a.txt && git add a.txt && git commit -q -m init
    echo b > b.txt  # uncommitted new file -> dirty count 1
) >/dev/null 2>&1
GIT_JSON=$(printf '{"session_id":"s","cwd":"%s","model":{"id":"x","display_name":"Opus"},"context_window":{"used_percentage":10}}' "$GIT_TMP")
OUT=$(run_with "$GIT_JSON")
assert_contains "$OUT" "main±1" "dirty branch rendered with count"
rm -rf "$GIT_TMP"

# Clean-repo variant: commit the file, dirty count drops to 0.
CURRENT_LABEL="git_clean"
GIT_TMP=$(mktemp -d)
(
    cd "$GIT_TMP"
    git init -q -b main
    git config user.email "t@t"
    git config user.name  "t"
    echo a > a.txt && git add a.txt && git commit -q -m init
) >/dev/null 2>&1
GIT_JSON=$(printf '{"session_id":"s","cwd":"%s","model":{"id":"x","display_name":"Opus"},"context_window":{"used_percentage":10}}' "$GIT_TMP")
OUT=$(run_with "$GIT_JSON")
assert_contains "$OUT" "main"   "clean branch rendered"
assert_missing  "$OUT" "±"      "no dirty marker on clean repo"
rm -rf "$GIT_TMP"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -gt 0 ] && exit 1
exit 0
