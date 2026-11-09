#!/usr/bin/env bash
# Lock screen (hyprlock, ~/.config/hypr/hyprlock.conf) over a pre-blurred
# copy of the current wallpaper.  Old swaylock version: lock.sh.swaylock
#   lock.sh          -> lock now (instant: just shows the cached image)
#   lock.sh cache    -> (re)build the blurred cache for the current wallpaper
# wallpaper.sh calls `lock.sh cache` whenever you pick a new wallpaper.
MAGICK=$(command -v magick || echo "$HOME/.local/state/gcroots/imagemagick/bin/magick")
WALL=$(readlink -f "$HOME/.config/sway/current-wallpaper")
CACHEDIR=$HOME/.cache/lockscreen
mkdir -p "$CACHEDIR"

# One cached file per wallpaper (keyed on path + modification time), so
# switching back to an old wallpaper doesn't re-blur it.
key=$(printf '%s %s' "$WALL" "$(stat -c %Y "$WALL" 2>/dev/null)" | md5sum | cut -c1-16)
BLUR=$CACHEDIR/$key.png

build() {
  [ -f "$BLUR" ] && return
  # Downscale -> blur -> upscale is ~10x faster than blurring at full size
  # and looks the same once blurred. Slight darken keeps the clock readable.
  "$MAGICK" "$WALL" -resize 1920x1080^ -gravity center -extent 1920x1080 \
    -scale 25% -blur 0x5 -resize 400% \
    -fill black -colorize 25% \
    "$BLUR.tmp.png" && mv "$BLUR.tmp.png" "$BLUR"
  # Keep only the 10 most recent blurs.
  find "$CACHEDIR" -maxdepth 1 -type f -name "*.png" ! -name "*.tmp.png" -printf "%T@ %p\n" | sort -rn | tail -n +11 | cut -d" " -f2- | xargs -r -d "\n" rm --
}

sync_greeter() { ( ln -sfn "$BLUR" "$CACHEDIR/current.png"; ~/.config/sway/greeter-sync.sh ) & }

case $1 in
  cache) build && sync_greeter; exit ;;
esac

# system packages first; pinned copies only as a fallback
export PATH=$PATH:$HOME/.local/state/gcroots/hyprlock/bin:$HOME/.local/state/gcroots/playerctl/bin
pgrep -x hyprlock >/dev/null && exit 0   # already locked

# hyprlock.conf reads ~/.cache/lockscreen/current.png
build
if [ -f "$BLUR" ]; then
  ln -sfn "$BLUR" "$CACHEDIR/current.png"
else
  ln -sfn "$WALL" "$CACHEDIR/current.png"
fi

# hyprlock stays in the foreground; run it detached and wait until the
# session lock is up, so swayidle's before-sleep doesn't suspend first.
setsid -f hyprlock >"$CACHEDIR/hyprlock.log" 2>&1
for _ in $(seq 20); do pgrep -x hyprlock >/dev/null && break; sleep 0.05; done
sleep 0.3
