#!/usr/bin/env bash
#
# Prepares a simulator for App Store captures and takes them.
#
#   capture-shots.sh prepare <udid>           # clean status bar, 9:41, full battery
#   capture-shots.sh shot <udid> out/01.png   # capture at native resolution
#   capture-shots.sh tap <udid> <x> <y>       # point coordinates, not pixels
#   capture-shots.sh swipe <udid> x1 y1 x2 y2
#
# Capture on a simulator whose display matches the size you are uploading, so
# nothing is rescaled. 6.9" is 1320x2868 and App Store Connect scales it down
# for every other device, so one set is enough.
#
# Two things that waste a session:
#   - Shut every other simulator down first. idb acts on whichever is booted.
#   - A landscape screen still comes out in the portrait frame. Rotate the file
#     afterwards with: sips -r 270 shot.png

set -euo pipefail

command="${1:-}"
udid="${2:-}"
[ -n "$command" ] && [ -n "$udid" ] || { sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }

case "$command" in
  prepare)
    xcrun simctl bootstatus "$udid" -b >/dev/null 2>&1 || xcrun simctl boot "$udid"
    xcrun simctl status_bar "$udid" override \
      --time "9:41" \
      --batteryState charged --batteryLevel 100 \
      --cellularMode active --cellularBars 4 \
      --wifiMode active --wifiBars 3
    echo "status bar pinned on $udid"
    ;;
  shot)
    out="${3:?output path required}"
    mkdir -p "$(dirname "$out")"
    xcrun simctl io "$udid" screenshot "$out" >/dev/null 2>&1
    echo "$out  $(sips -g pixelWidth -g pixelHeight "$out" | awk '/pixel/{printf "%s ", $2}')"
    ;;
  tap)
    idb ui tap --udid "$udid" "${3:?x}" "${4:?y}"
    ;;
  swipe)
    idb ui swipe --udid "$udid" "${3:?x1}" "${4:?y1}" "${5:?x2}" "${6:?y2}"
    ;;
  *)
    echo "unknown command: $command" >&2
    exit 2
    ;;
esac
