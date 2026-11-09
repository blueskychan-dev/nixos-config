#!/usr/bin/env bash
# Wallpaper picker: rofi grid of thumbnails from $WALLDIRS, applies to all
# screens and remembers the choice across reloads/reboots.
#   wallpaper.sh            -> open picker
#   wallpaper.sh restore    -> re-apply last choice (used at sway startup)
#   wallpaper.sh random     -> pick a random one
# Folders to scan (space-separated). Shown in the picker relative to ~/Pictures.
WALLDIRS=${WALLDIRS:-"$HOME/Pictures/wallpaper $HOME/Pictures/yuriwallpaper"}
BASE=$HOME/Pictures
CURRENT=$HOME/.config/sway/current-wallpaper   # symlink to the chosen image
MODE=${MODE:-fill}                             # fill | fit | stretch | center | tile

apply() {
  ln -sfn "$1" "$CURRENT"
  swaymsg -q "output * bg \"$1\" $MODE"
  ( ~/.config/sway/lock.sh cache & )   # pre-blur for the lock screen
}

mapfile -t files < <(find -L $WALLDIRS -maxdepth 2 -type f \
  \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \) | sort)

case $1 in
  restore)
    [ -e "$CURRENT" ] && swaymsg -q "output * bg \"$(readlink -f "$CURRENT")\" $MODE"
    exit ;;
  random)
    ((${#files[@]})) && apply "${files[RANDOM % ${#files[@]}]}"
    exit ;;
esac

if ((${#files[@]} == 0)); then
  rofi -e "No images in $WALLDIRS"
  exit 1
fi

choice=$(
  for f in "${files[@]}"; do
    printf '%s\0icon\x1f%s\n' "${f#$BASE/}" "$f"
  done | rofi -dmenu -i -show-icons -p "Wallpaper" \
      -theme-str 'window { width: 70%; }
                  listview { columns: 4; lines: 3; flow: horizontal; spacing: 12px; }
                  element { orientation: vertical; padding: 8px; border-radius: 8px; }
                  element-icon { size: 180px; horizontal-align: 0.5; }
                  element-text { horizontal-align: 0.5; }'
)
[ -n "$choice" ] && apply "$BASE/$choice"
