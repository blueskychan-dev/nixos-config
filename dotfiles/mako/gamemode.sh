#!/run/current-system/sw/bin/bash
# Called by gamemoded (~/.config/gamemode.ini [custom] start/end):
#   gamemode.sh start  -> hide notifications while any game runs (mako mode "game")
#   gamemode.sh end    -> show them again
# Uses its own mako mode, so it never touches your manual Do Not Disturb.
# Critical notifications still show (see ~/.config/mako/config).
export PATH=/run/current-system/sw/bin:/run/wrappers/bin:$PATH
export DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}

case $1 in
  start) makoctl mode -a game >/dev/null ;;
  end)   makoctl mode -r game >/dev/null ;;
  *)     echo "usage: ${0##*/} start|end" >&2; exit 2 ;;
esac
pkill -RTMIN+9 -f '^waybar' 2>/dev/null   # refresh the bell
exit 0
