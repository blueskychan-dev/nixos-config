#!/usr/bin/env bash
# Waybar module for mako: bell (+ count when there are notifications).
#   status.sh            -> JSON for waybar
#   status.sh clear      -> dismiss all
#   status.sh dnd        -> toggle Do Not Disturb (mako mode "dnd")
case $1 in
  clear) makoctl dismiss -a; pkill -RTMIN+9 -f '^waybar'; exit ;;
  click)  # left-click: clear if there are notifications, otherwise show history
    if [ "$(makoctl list -j | python3 -Ic 'import json,sys; print(len(json.load(sys.stdin)))')" -gt 0 ]; then
      makoctl dismiss -a; pkill -RTMIN+9 -f '^waybar'
    else
      exec ~/.config/mako/history.sh
    fi; exit ;;
  dnd)   makoctl mode -t dnd >/dev/null; pkill -RTMIN+9 -f '^waybar'; exit ;;
esac

n=$(makoctl list -j 2>/dev/null | python3 -Ic 'import json,sys; print(len(json.load(sys.stdin)))' 2>/dev/null)
n=${n:-0}
modes=$(makoctl mode 2>/dev/null)
if grep -qx game <<<"$modes"; then
  printf '{"text":"\U000F0297%s","class":"game","tooltip":"Game mode — notifications paused until the game exits"}\n' \
    "$([ "$n" -gt 0 ] && echo " $n")"
elif grep -qx dnd <<<"$modes"; then
  printf '{"text":"\U000F009B%s","class":"dnd","tooltip":"Do Not Disturb is on — right-click to turn off"}\n' \
    "$([ "$n" -gt 0 ] && echo " $n")"
elif [ "$n" -gt 0 ]; then
  printf '{"text":"\U000F009A %s","class":"has","tooltip":"%s notification(s)\\nClick: clear all · Middle: history · Right: Do Not Disturb"}\n' "$n" "$n"
else
  printf '{"text":"\U000F009A","class":"none","tooltip":"No notifications\\nClick: history · Right-click: Do Not Disturb"}\n'
fi
