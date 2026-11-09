#!/usr/bin/env bash
# Click the clock in waybar: open a small calendar; click the clock again to close.
# (Hovering the clock still shows the quick tooltip calendar.)
if pkill -f '^zenity --calendar --title=Calendar' 2>/dev/null; then
  exit 0
fi
exec zenity --calendar --title=Calendar --text="$(date '+%A %d %B %Y')" \
  --ok-label="OK" --cancel-label="Close" >/dev/null 2>&1
