#!/usr/bin/env bash
# Sync the live config from /etc/nixos and ~/.config into this repo.
#
#   ./sync.sh          copy /etc/nixos and ~/.config -> repo
#   ./sync.sh --dry    show what would change, copy nothing
#   ./sync.sh --push   copy, then commit and push
#
set -euo pipefail

SRC=/etc/nixos
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST="$(hostname)"

# source file in /etc/nixos  ->  destination path inside the repo.
# Add a line here when you add a new .nix file to /etc/nixos.
declare -A FILES=(
  [configuration.nix]="hosts/$HOST/configuration.nix"
  [hardware-configuration.nix]="hosts/$HOST/hardware-configuration.nix"
  [flake.nix]="flake.nix"
  [flake.lock]="flake.lock"
  [desktop.nix]="modules/desktop.nix"
  [packages.nix]="modules/packages.nix"
  [gaming.nix]="modules/gaming.nix"
  [virtualisation.nix]="modules/virtualisation.nix"
  [tweaks.nix]="modules/tweaks.nix"
)

# directory under ~/.config  ->  destination directory inside the repo.
# Every file below the source is copied, recursively, minus SKIP below.
declare -A DIRS=(
  [alacritty]="dotfiles/alacritty"
  [cava]="dotfiles/cava"
  [dconf]="dotfiles/dconf"
  [mako]="dotfiles/mako"
  [nemo]="dotfiles/nemo"
  [pipewire]="dotfiles/pipewire"
  [rofi]="dotfiles/rofi"
  [sway]="dotfiles/sway"
  [waybar]="dotfiles/waybar"
)

# Filename globs never copied out of ~/.config.
SKIP=('*.bak' '*.tmp' '*.swp' '*~')

DRY=0
PUSH=0
for arg in "$@"; do
  case "$arg" in
    --dry|--dry-run) DRY=1 ;;
    --push) PUSH=1 ;;
    -h|--help) sed -n '2,7p' "${BASH_SOURCE[0]}" | cut -c3-; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

changed=0
missing=0

# copy one file into the repo, or describe the copy under --dry.
sync_file() {
  local src="$1" dest="$2" target="$REPO/$2"
  if [[ -f "$target" ]] && cmp -s "$src" "$target"; then
    return
  fi
  changed=1
  if [[ $DRY -eq 1 ]]; then
    echo "would update: $dest"
    diff -u --label "repo/$dest" --label "$src" "$target" "$src" 2>/dev/null || true
  else
    mkdir -p "$(dirname "$target")"
    cp "$src" "$target"
    echo "updated: $dest"
  fi
}

skipped() {
  local glob
  for glob in "${SKIP[@]}"; do
    # shellcheck disable=SC2053  # $glob is a pattern on purpose
    [[ $(basename "$1") == $glob ]] && return 0
  done
  return 1
}

for src in "${!FILES[@]}"; do
  if [[ ! -f "$SRC/$src" ]]; then
    echo "missing in $SRC: $src"
    missing=1
    continue
  fi
  for dest in ${FILES[$src]}; do
    sync_file "$SRC/$src" "$dest"
  done
done

for dir in "${!DIRS[@]}"; do
  if [[ ! -d "$CONF/$dir" ]]; then
    echo "missing in $CONF: $dir"
    missing=1
    continue
  fi
  while IFS= read -r -d '' f; do
    if skipped "$f"; then
      continue
    fi
    sync_file "$f" "${DIRS[$dir]}/${f#"$CONF/$dir/"}"
  done < <(find "$CONF/$dir" -type f -print0 | sort -z)
done

# Warn about .nix files in /etc/nixos that the table above doesn't know about.
while IFS= read -r f; do
  base="$(basename "$f")"
  [[ -v FILES[$base] ]] || echo "untracked in $SRC: $base (add it to FILES in sync.sh)"
done < <(find "$SRC" -maxdepth 1 -name '*.nix' -type f)

# Warn about dotfiles kept in the repo that no ~/.config directory feeds.
while IFS= read -r d; do
  base="$(basename "$d")"
  [[ -v DIRS[$base] ]] || echo "not synced from $CONF: dotfiles/$base (add it to DIRS in sync.sh)"
done < <(find "$REPO/dotfiles" -mindepth 1 -maxdepth 1 -type d)

if [[ $changed -eq 0 ]]; then
  echo "already in sync"
  exit $missing
fi

[[ $DRY -eq 1 ]] && exit 0

cd "$REPO"
git add -A
git --no-pager diff --cached --stat

if [[ $PUSH -eq 1 ]]; then
  git commit -m "Sync config from /etc/nixos"
  git push
else
  echo
  echo "staged. commit with: git commit -m 'Sync config from /etc/nixos'"
fi

exit $missing
