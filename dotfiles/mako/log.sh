#!/usr/bin/env bash
# mako on-notify hook: append the new notification to the history log and
# refresh the waybar bell.   Log: ~/.cache/notifications.jsonl (newest last)
LOG=$HOME/.cache/notifications.jsonl
KEEP=300
id=${id:-$1}

if [ -n "$id" ]; then
  makoctl list -j 2>/dev/null | python3 -Ic '
import json, sys, time
nid = int(sys.argv[1])
for n in json.load(sys.stdin):
    if n.get("id") == nid:
        rec = {k: n.get(k) for k in ("app_name", "summary", "body", "app_icon", "desktop_entry")}
        rec["actions"] = list((n.get("actions") or {}).keys())
        rec["time"] = int(time.time())
        print(json.dumps(rec, ensure_ascii=False))
        break' "$id" >> "$LOG"
  # trim (cheap: only when it has grown well past KEEP)
  if [ "$(wc -l < "$LOG")" -gt $((KEEP + 50)) ]; then
    tail -n $KEEP "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
  fi
fi
pkill -RTMIN+9 -f '^waybar' 2>/dev/null
exit 0
