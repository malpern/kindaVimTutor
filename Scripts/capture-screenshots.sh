#!/usr/bin/env bash
#
# Rebuild the app bundle, launch it into each of a curated set of
# initial states, capture a window screenshot with peekaboo, and write
# the resulting PNGs into docs/screenshots/. States are passed in via
# --initial-state; AppState parses them on launch (see AppState.swift).
#
# Requires: peekaboo CLI, Screen Recording + Accessibility permissions.
#
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

SHOTS="docs/screenshots"
APP="$ROOT/KindaVimTutor.app"
BIN="$APP/Contents/MacOS/KindaVimTutor"

mkdir -p "$SHOTS"

echo "==> Building app bundle…"
bash Scripts/package_app.sh debug >/dev/null

kill_app() {
  pkill -f "KindaVimTutor.app/Contents/MacOS/KindaVimTutor" 2>/dev/null || true
  # Give macOS a moment to release the window list.
  sleep 0.7
}

# Find the main (largest) window of the running app by ID.
find_window_id() {
  peekaboo list windows --app KindaVimTutor 2>/dev/null \
    | awk '
      /ID: [0-9]+/ {
        id=$0
        sub(/.*ID: /, "", id)
        sub(/[^0-9].*/, "", id)
      }
      /Size: [0-9]+×[0-9]+/ && id != "" {
        sz=$0
        sub(/.*Size: /, "", sz)
        split(sz, a, /[×[:space:]]/)
        w=a[1]+0
        h=a[2]+0
        if (w*h > best) { best = w*h; bestid = id }
      }
      END { if (bestid) print bestid }
    '
}

capture() {
  local state="$1"
  local name="$2"

  echo "==> $name  ($state)"
  kill_app
  # Launch the fresh bundle with a state arg.
  "$BIN" --initial-state "$state" >/dev/null 2>&1 &
  local pid=$!
  # Wait for the window to come up.
  for i in 1 2 3 4 5 6 7 8 9 10; do
    sleep 0.6
    wid=$(find_window_id || true)
    if [ -n "${wid:-}" ]; then break; fi
  done

  if [ -z "${wid:-}" ]; then
    echo "   ! couldn't find window"
    kill -TERM "$pid" 2>/dev/null || true
    return
  fi

  # Let a first-frame animation settle.
  sleep 0.5

  peekaboo image --window-id "$wid" --path "$SHOTS/$name.png" >/dev/null
  echo "   saved $SHOTS/$name.png"

  kill -TERM "$pid" 2>/dev/null || true
}

# Curated screenshot set. Add/remove as the tutorial needs grow.
capture "welcome"                 "01-welcome"
capture "lesson:ch1.l1"           "02-title-slide"
capture "lesson:ch1.l1:1"         "03-content-slide"
capture "lesson:ch1.l1:2"         "04-content-slide-2"
capture "lesson:ch1.l1:3"         "05-drill"

kill_app
echo "==> Done. Screenshots in $SHOTS/"
