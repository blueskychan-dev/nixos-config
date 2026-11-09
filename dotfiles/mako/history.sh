#!/usr/bin/env bash
# Notification history (rofi). Mod+Shift+N, or middle-click the bell in waybar.
# Pick an entry to open it: screenshot -> image, link in text -> browser,
# otherwise focus the app. First row clears the history.
LOG=$HOME/.cache/notifications.jsonl
SHOW=150
[ -s "$LOG" ] || : > "$LOG"
pgrep -x rofi >/dev/null && exit 0

# Build rows: two lines each, \x0f-separated, with pango markup.
# Also writes the matching "kind<TAB>arg" for every row to a temp file.
targets=$(mktemp); trap 'rm -f "$targets"' EXIT
rows=$(tail -n $SHOW "$LOG" | python3 -Ic '
import json, os, re, sys, time
from html import escape
recs = []
for line in sys.stdin:
    try: recs.append(json.loads(line))
    except ValueError: pass
recs.reverse()                                   # newest first
today = time.strftime("%Y-%m-%d")
out_rows, out_targets = [], []
n = len(recs)
out_rows.append(f"<b>󰎟  Clear history</b>\n<span alpha=\"55%\">{n} notification{"s" if n != 1 else ""}</span>")
out_targets.append("clear\t")
for r in recs:
    t = r.get("time") or 0
    when = time.strftime("%H:%M", time.localtime(t)) if time.strftime("%Y-%m-%d", time.localtime(t)) == today \
           else time.strftime("%d %b %H:%M", time.localtime(t))
    app = r.get("app_name") or "?"
    summ = " ".join((r.get("summary") or "").split())
    body = " ".join(re.sub(r"<[^>]+>", "", r.get("body") or "").split())
    text = (summ + ("  —  " + body if body else ""))[:110]
    out_rows.append(f"<span alpha=\"55%\">{escape(when)}  ·  {escape(app)}</span>\n{escape(text)}")
    icon = r.get("app_icon") or ""
    url = re.search(r"(https?://[^\s<>\"]+|www\.[^\s<>\"]+)", f"{summ} {body}")
    if app == "Screenshot" and os.path.isfile(icon):
        out_targets.append("open\t" + icon)
    elif url:
        u = url.group(1).rstrip(".,;:!?)]}")
        out_targets.append("open\t" + (u if u.startswith("http") else "https://" + u))
    else:
        out_targets.append("focus\t" + (r.get("desktop_entry") or app))
with open(sys.argv[1], "w") as f:
    f.write("\n".join(out_targets) + "\n")
sys.stdout.write("\x0f".join(out_rows))
' "$targets")

idx=$(printf '%s' "$rows" | rofi -dmenu -i -markup-rows -sep $'\x0f' -eh 2 -format i \
        -p "󰂚  Notifications" \
        -theme-str 'window { width: 640px; } listview { lines: 7; }') || exit 0
[ -n "$idx" ] || exit 0

IFS=$'\t' read -r kind arg < <(sed -n "$((idx + 1))p" "$targets")
case $kind in
  clear) : > "$LOG"; pkill -RTMIN+9 -f '^waybar' ;;
  open)  setsid -f xdg-open "$arg" >/dev/null 2>&1 ;;
  focus) ~/.config/mako/focus-app.sh "$arg" ;;
esac
