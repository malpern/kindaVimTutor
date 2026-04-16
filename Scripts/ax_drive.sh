#!/usr/bin/env bash
# ax_drive.sh — drive a running KindaVimTutor instance via its command channel.
# The app, when launched with KINDAVIMTUTOR_ENABLE_CHANNEL=1, polls
# $LOG_DIR/commands.in and mirrors its state to $LOG_DIR/state.json.
# Default LOG_DIR is ~/Library/Logs/KindaVimTutor.
#
# Usage:
#   ax_drive.sh status
#   ax_drive.sh send <command> [args...]
#   ax_drive.sh wait-step <expected-kind> [timeout-seconds]
#   ax_drive.sh tail [log-name]        # follow app.log
#   ax_drive.sh reset                  # clear command queue + state mirror
#
# Commands supported by the app (send verbatim):
#   next, prev, goto <index>, startFirstLesson, nextLesson,
#   selectLesson <id>, type <text>, key <space|l|h|forward|backward>

set -euo pipefail

LOG_DIR="${KINDAVIMTUTOR_LOG_DIR:-$HOME/Library/Logs/KindaVimTutor}"
CMD_FILE="$LOG_DIR/commands.in"
STATE_FILE="$LOG_DIR/state.json"
APP_LOG="$LOG_DIR/app.log"

ensure_dir() { mkdir -p "$LOG_DIR"; }

require_running() {
    if ! pgrep -f 'KindaVimTutor.app/Contents/MacOS/KindaVimTutor' >/dev/null 2>&1 \
       && ! pgrep -f '.build/debug/KindaVimTutor' >/dev/null 2>&1 \
       && ! pgrep -f '.build/release/KindaVimTutor' >/dev/null 2>&1; then
        echo "KindaVimTutor is not running. Launch it first with:" >&2
        echo "  KINDAVIMTUTOR_ENABLE_CHANNEL=1 open <path-to-KindaVimTutor.app>" >&2
        exit 2
    fi
}

status() {
    ensure_dir
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    else
        echo '{"error":"no state file — is the app running with KINDAVIMTUTOR_ENABLE_CHANNEL=1?"}'
        exit 1
    fi
}

send() {
    ensure_dir
    local cmd="$*"
    printf '%s\n' "$cmd" >> "$CMD_FILE"
}

wait_step() {
    local expected="$1"
    local timeout="${2:-10}"
    ensure_dir
    local deadline=$(( $(date +%s) + timeout ))
    while (( $(date +%s) < deadline )); do
        if [[ -f "$STATE_FILE" ]]; then
            local kind
            kind=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("stepKind",""))' "$STATE_FILE" 2>/dev/null || echo "")
            if [[ "$kind" == "$expected" ]]; then
                return 0
            fi
        fi
        sleep 0.25
    done
    echo "Timed out waiting for stepKind=$expected; last state:" >&2
    status >&2
    return 1
}

tail_log() {
    ensure_dir
    local name="${1:-app.log}"
    local file="$LOG_DIR/$name"
    if [[ ! -f "$file" ]]; then
        echo "No log file yet at $file" >&2
        exit 1
    fi
    exec tail -F "$file"
}

reset_channel() {
    ensure_dir
    : > "$CMD_FILE"
    rm -f "$STATE_FILE"
}

case "${1:-}" in
    status) status ;;
    send) shift; require_running; send "$@" ;;
    wait-step) shift; wait_step "$@" ;;
    tail) shift; tail_log "$@" ;;
    reset) reset_channel ;;
    *)
        cat >&2 <<USAGE
Usage:
  $0 status                      # prints state.json
  $0 send <command> [args...]    # appends a command to commands.in
  $0 wait-step <kind> [secs]     # blocks until stepKind matches
  $0 tail [log-name]             # follows app.log (default) or another file
  $0 reset                       # clears the command queue + state mirror

LOG_DIR is \$KINDAVIMTUTOR_LOG_DIR (default: ~/Library/Logs/KindaVimTutor).
USAGE
        exit 64
        ;;
esac
