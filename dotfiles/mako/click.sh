#!/usr/bin/env bash
# Left-click handler for mako (on-button-left=exec ~/.config/mako/click.sh).
# mako passes the notification id in $id. Order of preference:
#   0. screenshots -> open the image
#   1. the app's "default" action      (Discord/Telegram/browsers jump to the message)
#   2. first URL in the text           -> open in the default browser
#   3. any other actions               -> pick one in rofi
#   4. focus the sending app's window
# …then dismiss the notification.
id=${id:-$1}
[ -n "$id" ] || exit 0

json=$(makoctl list -j)
read -r -d '' PY <<'EOF'
import json, os, re, sys
nid = int(sys.argv[1])
n = next((x for x in json.load(sys.stdin) if x.get("id") == nid), None)
if not n:
    print("none"); sys.exit()
acts = n.get("actions") or {}
text = f'{n.get("summary") or ""} {n.get("body") or ""}'
url = re.search(r'(https?://[^\s<>"\']+|www\.[^\s<>"\']+)', text)
icon = n.get("app_icon") or ""
if n.get("app_name") == "Screenshot" and os.path.isfile(icon):
    print("url", icon)                       # open the screenshot itself
elif "default" in acts:
    print("default")
elif url:
    u = url.group(1).rstrip(".,;:!?)]}")
    print("url", u if u.startswith("http") else "https://" + u)
elif acts:
    print("menu")
else:
    print("focus", n.get("desktop_entry") or n.get("app_name") or "")
EOF
read -r kind arg < <(printf '%s' "$json" | python3 -Ic "$PY" "$id")

case $kind in
  default) makoctl invoke -n "$id" default ;;
  url)     setsid -f xdg-open "$arg" >/dev/null 2>&1 ;;
  menu)    makoctl menu -n "$id" -- rofi -dmenu -i -p "Action" ;;
  focus)   ~/.config/mako/focus-app.sh "$arg" ;;
esac
makoctl dismiss -n "$id" 2>/dev/null
exit 0
