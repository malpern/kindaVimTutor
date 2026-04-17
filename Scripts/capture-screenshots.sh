#!/usr/bin/env bash
#
# Regenerate tutorial screenshots deterministically from the real app.
#
# Each capture:
#   1. Rebuilds the app bundle (once, up front).
#   2. Launches the app with --initial-state set, in an isolated
#      KINDAVIM_PROGRESS_DIR so real user progress isn't touched.
#   3. Captures the window with peekaboo.
#   4. Optionally crops with sips to produce zoomed-in detail shots.
#
# Requires peekaboo CLI with Screen Recording + Accessibility permissions.
#
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

SHOTS="docs/screenshots"
APP="$ROOT/KindaVimTutor.app"
BIN="$APP/Contents/MacOS/KindaVimTutor"
ISOLATED_PROGRESS_DIR=$(mktemp -d -t kvt-shots.XXXXXX)

mkdir -p "$SHOTS"

cleanup() {
  pkill -f "KindaVimTutor.app/Contents/MacOS/KindaVimTutor" 2>/dev/null || true
  rm -rf "$ISOLATED_PROGRESS_DIR"
}
trap cleanup EXIT

echo "==> Building app bundle…"
bash Scripts/package_app.sh debug >/dev/null

kill_app() {
  pkill -f "KindaVimTutor.app/Contents/MacOS/KindaVimTutor" 2>/dev/null || true
  sleep 0.7
}

# Pick the main (largest) window of the running app by ID.
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

# capture STATE NAME [EXTRA_ARGS...]
capture() {
  local state="$1"
  local name="$2"
  shift 2

  echo "==> $name  ($state)"
  kill_app
  rm -rf "$ISOLATED_PROGRESS_DIR" && mkdir -p "$ISOLATED_PROGRESS_DIR"

  KINDAVIM_PROGRESS_DIR="$ISOLATED_PROGRESS_DIR" \
    "$BIN" --initial-state "$state" "$@" >/dev/null 2>&1 &
  local pid=$!

  # Wait for the window.
  local wid=""
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    sleep 0.6
    wid=$(find_window_id || true)
    if [ -n "${wid:-}" ]; then break; fi
  done

  if [ -z "${wid:-}" ]; then
    echo "   ! couldn't find window"
    kill -TERM "$pid" 2>/dev/null || true
    return
  fi

  # Let first-frame animation settle.
  sleep 0.6
  peekaboo image --window-id "$wid" --path "$SHOTS/$name.png" >/dev/null
  echo "   saved $SHOTS/$name.png"

  kill -TERM "$pid" 2>/dev/null || true
}

# crop SOURCE DEST X Y WIDTH HEIGHT
# Coordinates are a top-left rect in pixels. Uses CoreGraphics through the
# Scripts/crop-png.swift helper — sips's cropOffset semantics aren't
# stable enough to rely on.
crop() {
  local src="$SHOTS/$1"
  local dst="$SHOTS/$2"
  local x="$3" y="$4" w="$5" h="$6"

  if [ ! -f "$src" ]; then
    echo "   ! crop: missing source $src"
    return
  fi

  /usr/bin/swift "$ROOT/Scripts/crop-png.swift" "$src" "$dst" "$x" "$y" "$w" "$h"
  echo "   cropped $SHOTS/$2 (${w}×${h} @ ${x},${y})"
}

# ---------------------------------------------------------------
# Curated screenshot set. Rebuild when the tutorial needs change.
# ---------------------------------------------------------------

# Full-window captures
capture "welcome"                 "01-welcome"
capture "lesson:ch1.l1"           "02-title-slide"
capture "lesson:ch1.l1:1"         "03-content-slide"
capture "lesson:ch1.l1:3"         "05-drill"

# Completed-lesson state: seed all five exercises of Moving the Cursor.
# Sidebar will render the lesson with a checkmark.
capture "lesson:ch1.l1" "09-sidebar-completed" \
  --seed-progress "ch1.l1.e1,ch1.l1.e2,ch1.l1.e3,ch1.l1.e4,ch1.l1.e5"

# ---------------------------------------------------------------
# Crops. Rects are in points (peekaboo captures match window size).
# Default window is 900 × 924 pts; adjust if the app resizes.
# ---------------------------------------------------------------

# Sidebar — top half of the left column. The content (chapter header +
# seven lesson rows) fits in the upper ~460pt; the lower half is empty.
crop "02-title-slide.png"        "06-sidebar-detail.png"          0 0 232 462
crop "09-sidebar-completed.png"  "09-sidebar-completed-crop.png"  0 0 232 462

# Lesson header detail — "SURVIVAL KIT / Moving the Cursor / Navigate with …"
crop "02-title-slide.png"        "08-header-detail.png"          300 370 540 160

# Drill editor detail — exercise label + instruction + editor.
crop "05-drill.png"              "07-editor-detail.png"          270 355 600 260

# Step indicator — six dots at the bottom of any slide.
crop "02-title-slide.png"        "10-step-indicator.png"         500 875 140 50

kill_app
echo ""
echo "==> Done. Screenshots in $SHOTS/"
ls -1 "$SHOTS" | sort
