#!/usr/bin/env bash
# Power menu (rofi). Mod+Shift+E or click the ⏻ in waybar.
pick=$(printf '%s\n' "󰌾  Lock" "󰍃  Log out" "󰒲  Suspend" "󰜉  Reboot" "󰐥  Shut down" \
  | rofi -dmenu -i -p "⏻" -theme-str 'window { width: 280px; } listview { lines: 5; } inputbar { enabled: false; }') || exit 0
case $pick in
  *Lock*)      ~/.config/sway/lock.sh ;;
  *"Log out"*) swaymsg exit ;;
  *Suspend*)   ~/.config/sway/lock.sh; sleep 0.5; systemctl suspend ;;
  *Reboot*)    systemctl reboot ;;
  *"Shut down"*) systemctl poweroff ;;
esac
