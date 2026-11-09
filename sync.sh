#!/usr/bin/env bash
# Sync the live config from /etc/nixos, ~/.config and $HOME into this repo.
#
#   ./sync.sh          copy everything -> repo, stage it
#   ./sync.sh --dry    show what would change, copy nothing
#   ./sync.sh --push   copy, then commit and push
#
set -euo pipefail

SRC=/etc/nixos
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST="$(hostname)"

# file in /etc/nixos  ->  destination inside the repo.
# Add a line here when you add a new file to /etc/nixos.
declare -A FILES=(
  [configuration.nix]="hosts/$HOST/configuration.nix"
  [hardware-configuration.nix]="hosts/$HOST/hardware-configuration.nix"
  [flake.nix]="flake.nix"
  [flake.lock]="flake.lock"
  [desktop.nix]="modules/desktop.nix"
  [greeter.nix]="modules/greeter.nix"
  [regreet.css]="modules/regreet.css"
  [files.nix]="modules/files.nix"
  [look.nix]="modules/look.nix"
  [packages.nix]="modules/packages.nix"
  [gaming.nix]="modules/gaming.nix"
  [virtualisation.nix]="modules/virtualisation.nix"
  [incus.nix]="modules/incus.nix"
  [tweaks.nix]="modules/tweaks.nix"
  [wireguard.nix]="modules/wireguard.nix"
  [sunshine.nix]="modules/sunshine.nix"
  [esp-idf.nix]="modules/esp-idf.nix"
)

# directory under ~/.config  ->  destination directory inside the repo.
# Every file below the source is copied, recursively, minus SKIP below.
declare -A DIRS=(
  [alacritty]="dotfiles/alacritty"
  [cava]="dotfiles/cava"
  [dconf]="dotfiles/dconf"
  [hypr]="dotfiles/hypr"
  [mako]="dotfiles/mako"
  [nemo]="dotfiles/nemo"
  [pipewire]="dotfiles/pipewire"
  [rofi]="dotfiles/rofi"
  [sway]="dotfiles/sway"
  [waybar]="dotfiles/waybar"
)

# single files under $HOME  ->  destination inside the repo.
declare -A HOME_FILES=(
  [.zshrc]="dotfiles/zsh/.zshrc"
  [.p10k.zsh]="dotfiles/zsh/.p10k.zsh"
  [.config/zsh/shortcuts.zsh]="dotfiles/zsh/shortcuts.zsh"
  [.local/bin/clean]="dotfiles/bin/clean"
  [.local/bin/gamemode-hold]="dotfiles/bin/gamemode-hold"
  [.local/bin/hw]="dotfiles/bin/hw"
  [.local/bin/keys]="dotfiles/bin/keys"
  [.local/bin/lab]="dotfiles/bin/lab"
  [.local/bin/motd-rice]="dotfiles/bin/motd-rice"
  [.local/bin/music-popup]="dotfiles/bin/music-popup"
  [.local/bin/net]="dotfiles/bin/net"
  [.local/bin/pc]="dotfiles/bin/pc"
  [.local/bin/upd]="dotfiles/bin/upd"
)

# Filename globs never copied (backups, editor leftovers, symlinks are skipped too).
SKIP=('*.bak' '*.bak[-.]*' '*.tmp' '*.swp' '*~' '*.swaylock' '*.pre-*')

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
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Rewrite a source file for its place in the repo. The live config is flat
# (everything in /etc/nixos); the repo splits hosts/ and modules/, so relative
# imports are adjusted to keep `nixos-rebuild --flake .#$HOST` working here.
transform() {
  local src="$1" dest="$2"
  case "$dest" in
    flake.nix)
      sed "s|\./configuration\.nix|./hosts/$HOST/configuration.nix|" "$src" ;;
    hosts/*/configuration.nix)
      sed -E '/hardware-configuration\.nix/! s|^(\s*)\./([A-Za-z0-9_-]+\.nix)|\1../../modules/\2|' "$src" ;;
    *)
      cat "$src" ;;
  esac
}

# Strings that must never reach the public repo (server IPs etc.), replaced in
# every text file. The list itself is private: it lives in .redact (git-ignored)
# as bash, e.g.   REDACT['203\.0\.113\.7']="SERVER_IP"
declare -A REDACT=()
if [[ -f "$REPO/.redact" ]]; then
  # shellcheck source=/dev/null
  source "$REPO/.redact"
else
  echo "warning: no .redact file, nothing will be redacted" >&2
fi

redact() {   # in place; binary files (grep -I sees a NUL) are left untouched
  local expr=() k
  grep -qI . "$1" || return 0
  for k in "${!REDACT[@]}"; do expr+=(-e "s|$k|${REDACT[$k]}|g"); done
  sed -i -E "${expr[@]}" "$1"
}

# copy one file into the repo, or describe the copy under --dry.
sync_file() {
  local src="$1" dest="$2" target="$REPO/$2" staged="$TMP/staged"
  transform "$src" "$dest" > "$staged"
  redact "$staged"
  if [[ -f "$target" ]] && cmp -s "$staged" "$target"; then
    return
  fi
  changed=1
  if [[ $DRY -eq 1 ]]; then
    echo "would update: $dest"
  else
    mkdir -p "$(dirname "$target")"
    cp "$staged" "$target"
    [[ -x "$src" ]] && chmod +x "$target"
    echo "updated: $dest"
  fi
}

# remove a repo file whose source is gone (or now skipped).
prune_file() {
  changed=1
  if [[ $DRY -eq 1 ]]; then
    echo "would remove: $1"
  else
    rm -f "$REPO/$1"
    echo "removed: $1"
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
  sync_file "$SRC/$src" "${FILES[$src]}"
done

for src in "${!HOME_FILES[@]}"; do
  if [[ ! -f "$HOME/$src" ]]; then
    echo "missing in \$HOME: $src"
    missing=1
    continue
  fi
  sync_file "$HOME/$src" "${HOME_FILES[$src]}"
done

for dir in "${!DIRS[@]}"; do
  dest="${DIRS[$dir]}"
  if [[ ! -d "$CONF/$dir" ]]; then
    echo "missing in $CONF: $dir"
    missing=1
    continue
  fi
  while IFS= read -r -d '' f; do
    skipped "$f" && continue
    sync_file "$f" "$dest/${f#"$CONF/$dir/"}"
  done < <(find "$CONF/$dir" -type f -print0 | sort -z)

  # drop repo copies that no longer have a (non-skipped) source
  [[ -d "$REPO/$dest" ]] || continue
  while IFS= read -r -d '' f; do
    rel="${f#"$REPO/$dest/"}"
    if [[ ! -f "$CONF/$dir/$rel" ]] || skipped "$f"; then
      prune_file "$dest/$rel"
    fi
  done < <(find "$REPO/$dest" -type f -print0 | sort -z)
done

# Warn about files in /etc/nixos that the table above doesn't know about.
while IFS= read -r f; do
  base="$(basename "$f")"
  [[ -v FILES[$base] ]] || echo "untracked in $SRC: $base (add it to FILES in sync.sh)"
done < <(find "$SRC" -maxdepth 1 -type f \( -name '*.nix' -o -name '*.css' \))

# Warn about dotfiles kept in the repo that nothing feeds.
while IFS= read -r d; do
  base="$(basename "$d")"
  case "$base" in zsh|bin) continue ;; esac   # fed by HOME_FILES
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
