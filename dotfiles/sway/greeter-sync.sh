#!/usr/bin/env bash
# Keep the ReGreet login screen in sync with your setup.
# Copies the blurred wallpaper + a round avatar (from ~/.face) into
# /var/lib/greeter-theme/, which the greeter user can read.
# Called by lock.sh after it builds a blur; safe to run by hand any time.
OUT=/var/lib/greeter-theme
[ -d "$OUT" ] && [ -w "$OUT" ] || exit 0          # not set up (yet) — do nothing
MAGICK=$(command -v magick || echo "$HOME/.local/state/gcroots/imagemagick/bin/magick")
BLUR=$(readlink -f "$HOME/.cache/lockscreen/current.png")
FACE=$(readlink -f "$HOME/.face")

# Background: copy only if it changed.
if [ -f "$BLUR" ] && ! cmp -s "$BLUR" "$OUT/background.png"; then
  cp "$BLUR" "$OUT/background.png.tmp" && mv "$OUT/background.png.tmp" "$OUT/background.png"
fi

# Avatar: round crop with a peach -> rose ring; rebuild when ~/.face changes.
stamp=$OUT/.avatar-source
if [ -f "$FACE" ] && [ "$(cat "$stamp" 2>/dev/null)" != "$FACE $(stat -c %Y "$FACE")" ]; then
  tmp=$(mktemp -d)
  "$MAGICK" -size 236x236 xc:none -fill white -draw "circle 118,118 118,1" PNG32:"$tmp/m1.png"
  "$MAGICK" -size 256x256 xc:none -fill white -draw "circle 128,128 128,1" PNG32:"$tmp/m2.png"
  "$MAGICK" "$FACE" -resize 236x236^ -gravity center -extent 236x236 -alpha set PNG32:"$tmp/f.png"
  "$MAGICK" "$tmp/f.png" "$tmp/m1.png" -compose DstIn -composite PNG32:"$tmp/fr.png"
  "$MAGICK" -size 256x256 gradient:'#f4b183'-'#e0697a' -alpha set PNG32:"$tmp/g.png"
  "$MAGICK" "$tmp/g.png" "$tmp/m2.png" -compose DstIn -composite PNG32:"$tmp/r.png"
  "$MAGICK" "$tmp/r.png" "$tmp/fr.png" -gravity center -compose Over -composite PNG32:"$OUT/avatar.png.tmp" \
    && mv "$OUT/avatar.png.tmp" "$OUT/avatar.png" \
    && echo "$FACE $(stat -c %Y "$FACE")" > "$stamp"
  rm -rf "$tmp"
fi
chmod 644 "$OUT"/*.png 2>/dev/null
