#!/usr/bin/env bash
# focus-app.sh "<app name or desktop entry>"
# Focus the open window whose app_id/class contains EVERY word of the name,
# e.g. "Telegram Desktop" -> org.telegram.desktop. Exit 1 if none matches.
[ -n "$1" ] || exit 1
con=$(swaymsg -t get_tree -r | python3 -Ic '
import json, re, sys
want = [w for w in re.split(r"[^a-z0-9]+", sys.argv[1].lower()) if w]
def walk(n):
    if n.get("pid") and want:
        wp = n.get("window_properties") or {}
        hay = " ".join(str(x) for x in (n.get("app_id"), wp.get("class"), wp.get("instance"))).lower()
        if all(w in hay for w in want):
            print(n["id"]); sys.exit()
    for c in n.get("nodes", []) + n.get("floating_nodes", []): walk(c)
walk(json.load(sys.stdin))' "$1")
[ -n "$con" ] && swaymsg -q "[con_id=$con] focus"
