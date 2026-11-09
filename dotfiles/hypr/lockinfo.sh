#!/usr/bin/env bash
# Text for hyprlock labels. Kept out of hyprlock.conf because hyprlang
# parses things like {{ }} and # itself.
#   lockinfo.sh clock  -> date line + big time, as ONE label so they can't overlap
#   lockinfo.sh music  -> two-line now-playing block, empty when nothing plays
PATH=$PATH:$HOME/.local/state/gcroots/playerctl/bin

esc() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }

case $1 in
  clock)
    d=$(LC_TIME=C date '+%A  ·  %d %B' | tr '[:lower:]' '[:upper:]')
    t=$(date '+%H:%M')
    # 13pt spaced date, then 132pt thin time (sizes are 1024ths of a point)
    printf '<span size="13312" letter_spacing="4096" alpha="80%%">%s</span>\n<span font_family="JetBrainsMono Nerd Font" font_weight="100" size="135168">%s</span>\n' "$d" "$t"
    ;;
  music)
    [ "$(playerctl status 2>/dev/null)" = Playing ] || { echo; exit; }
    title=$(playerctl metadata title 2>/dev/null | cut -c1-48 | esc)
    artist=$(playerctl metadata artist 2>/dev/null | cut -c1-48 | esc)
    printf '<span size="small" letter_spacing="3072" alpha="60%%">NOW PLAYING</span>\n%s\n<span alpha="70%%">%s</span>\n' \
      "$title" "$artist"
    ;;
esac
