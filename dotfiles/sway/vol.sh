#!/usr/bin/env bash
# vol.sh up|down|mute|micmute — volume with the SwayOSD pop-up if available,
# plain wpctl otherwise (so keys keep working before SwayOSD is installed).
if command -v swayosd-client >/dev/null && pgrep -x swayosd-server >/dev/null; then
  case $1 in
    up)      exec swayosd-client --output-volume +5 --max-volume 100 ;;
    down)    exec swayosd-client --output-volume -5 ;;
    mute)    exec swayosd-client --output-volume mute-toggle ;;
    micmute) exec swayosd-client --input-volume mute-toggle ;;
  esac
fi
case $1 in
  up)      exec wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ ;;
  down)    exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
  mute)    exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
  micmute) exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle ;;
esac
