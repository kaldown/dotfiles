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

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -gt 0 ] && exit 1
exit 0
