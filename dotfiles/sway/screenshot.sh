#!/usr/bin/env bash
# ~/.config/sway/screenshot.sh — screenshots for sway.
# Saved to ~/Pictures/Screenshots AND copied to clipboard.
#
#   screenshot.sh region   freeze the screen, then drag-select an area
#   screenshot.sh full     capture all outputs immediately
#
# The freeze (wayfreeze) is what lets you capture menus, tooltips and other
# transient UI that would vanish the moment you started selecting.
#
# NOTE: wayfreeze 0.2.0 does NOT exit when --after-freeze-cmd finishes; it
# only exits on Escape or a mouse-button release. So the frozen pass kills
# it explicitly from an EXIT trap, which covers both capture and cancel.

set -uo pipefail

self=$(realpath "$0")
dir="$HOME/Pictures/Screenshots"

capture() {
    mkdir -p "$dir"
    local file="$dir/$(date +%Y%m%d-%H%M%S).png"
    grim "$@" - | tee "$file" | wl-copy
    [ -s "$file" ] && notify "$file"
}

# Notification with a thumbnail. Clicking it opens the image
# (handled by ~/.config/mako/click.sh: app "Screenshot" -> open its icon file).
notify() {
    local file=$1 size
    size=$(python3 -Ic 'import struct,sys; d=open(sys.argv[1],"rb").read(24); print("%dx%d" % struct.unpack(">II", d[16:24]))' "$file" 2>/dev/null)
    busctl --user call org.freedesktop.Notifications /org/freedesktop/Notifications \
        org.freedesktop.Notifications Notify susssasa{sv}i \
        "Screenshot" 0 "$file" "Screenshot saved ♡" \
        "Copied${size:+ · ${size/x/×}}"$'\n'"${file##*/}" \
        0 0 6000 >/dev/null 2>&1 &
}

case "${1:-region}" in
    region)
        # Re-enter under wayfreeze so slurp runs against a frozen screen.
        exec wayfreeze --hide-cursor --after-freeze-cmd "$self _frozen"
        ;;
    _frozen)
        trap 'pkill -x wayfreeze' EXIT   # always thaw, however we leave
        geom=$(slurp) || exit 0          # cancelled with Escape / right-click
        [ -n "$geom" ] || exit 0
        capture -g "$geom"
        ;;
    full)
        capture
        ;;
    *)
        echo "usage: ${0##*/} {region|full}" >&2
        exit 2
        ;;
esac
