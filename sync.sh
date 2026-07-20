#!/usr/bin/env bash
# Sync the live NixOS config from /etc/nixos into this repo.
#
#   ./sync.sh          copy /etc/nixos -> repo
#   ./sync.sh --dry    show what would change, copy nothing
#   ./sync.sh --push   copy, then commit and push
#
set -euo pipefail

SRC=/etc/nixos
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
)

DRY=0
PUSH=0
for arg in "$@"; do
  case "$arg" in
    --dry|--dry-run) DRY=1 ;;
    --push) PUSH=1 ;;
    -h|--help) sed -n '2,8p' "${BASH_SOURCE[0]}" | cut -c3-; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

changed=0
missing=0

for src in "${!FILES[@]}"; do
  if [[ ! -f "$SRC/$src" ]]; then
    echo "missing in $SRC: $src"
    missing=1
    continue
  fi
  for dest in ${FILES[$src]}; do
    target="$REPO/$dest"
    if [[ -f "$target" ]] && cmp -s "$SRC/$src" "$target"; then
      continue
    fi
    changed=1
    if [[ $DRY -eq 1 ]]; then
      echo "would update: $dest"
      diff -u --label "repo/$dest" --label "$SRC/$src" \
        "$target" "$SRC/$src" 2>/dev/null || true
    else
      mkdir -p "$(dirname "$target")"
      cp "$SRC/$src" "$target"
      echo "updated: $dest"
    fi
  done
done

# Warn about .nix files in /etc/nixos that the table above doesn't know about.
while IFS= read -r f; do
  base="$(basename "$f")"
  [[ -v FILES[$base] ]] || echo "untracked in $SRC: $base (add it to FILES in sync.sh)"
done < <(find "$SRC" -maxdepth 1 -name '*.nix' -type f)

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
