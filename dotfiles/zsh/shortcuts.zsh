# ~/.config/zsh/shortcuts.zsh — quick commands. Sourced from ~/.zshrc.
# Type `shortcuts` to see this list in the terminal.

# Terminal toys pinned in ~/.local/state/tools/bin until they're system packages
# (appended, so the system versions win after `nrb` + reboot).
path+=("$HOME/.local/state/tools/bin")

# ── Remote ──────────────────────────────────────────────────────────
alias ssh-to-miyabi='ssh mind@starloop.techtransthai.org -p 2233'
alias miyabi='ssh-to-miyabi'
alias oc='ssh oracle'             # Oracle ARM server (opc@ORACLE_IP)

# ── Containers / VMs ────────────────────────────────────────────────
# ct <name> : shell into an Incus container (starts it first if stopped)
ct() {
  local n=${1:-debian}
  if [[ $(incus list "^${n}\$" -f csv -c s 2>/dev/null) != RUNNING ]]; then
    incus start "$n" || return
    sleep 1
  fi
  incus exec "$n" -- bash -l
}
_ct() { compadd -- ${(f)"$(incus list -f csv -c n 2>/dev/null)"} }
compdef _ct ct 2>/dev/null
alias debian13='ct debian'           # Debian 13 LXC shell
alias cts='incus list'               # list containers
alias vms='virsh -c qemu:///system list --all'
# lab : fzf menu for Incus + QEMU (start/stop/shell/snapshot/console)
# net : fzf menu for Wi-Fi / LAN / WireGuard
# nightlight : fzf menu for the screen tint (off / auto / on, warmth, which monitors)

# ── Network ─────────────────────────────────────────────────────────
alias wgup='sudo systemctl start wg-quick-wg0'
alias wgdown='sudo systemctl stop wg-quick-wg0'
alias wgs='sudo wg show wg0'
alias myip='curl -s https://ifconfig.me; echo'
alias ports='ss -tulpn'

# ── Dotfiles (bare git repo in ~/.dotfiles — see ~/.config/dotfiles-README.md) ──
alias dots='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'

# ── NixOS ───────────────────────────────────────────────────────────
# nrs (already defined): flake update + switch
alias nrb='(cd /etc/nixos && sudo git add -A && sudo nixos-rebuild boot --flake .#mizukioverflow)'   # apply on next boot
alias nrt='(cd /etc/nixos && sudo git add -A && sudo nixos-rebuild test --flake .#mizukioverflow)'   # try now, not saved
# upd : check NixOS flake + Flatpak updates, preview, apply (fzf menu)
alias ngc='sudo nix-collect-garbage --delete-older-than 14d'

# ── Eye candy ───────────────────────────────────────────────────────
alias weather='curl -s "https://wttr.in/Nonthaburi?m&lang=th" | head -n 38'
alias weatherbar='curl -s "https://wttr.in/Nonthaburi?m&format=3"'
alias clock='tty-clock -c -s -b -C 5'          # big centred clock (q to quit)
alias matrix='cmatrix -b -u 5 -C magenta'       # hacker rain
alias hacker='matrix'
alias bonsai='cbonsai -l -i -t 0.02'            # grow a bonsai tree
alias pipes='pipes.sh -p 3 -r 2000'
alias vis='cava'                                # music visualiser
alias sys='btop'
alias temps='hw'                  # hw: live temps, load, GPU, disks (q quits)
alias ff='fastfetch'
alias motd='motd-rice'

# ── The list ────────────────────────────────────────────────────────
shortcuts() {
  local p=$'\e[38;2;250;179;135m' d=$'\e[38;2;108;112;134m' r=$'\e[0m'
  print -P ""
  printf "  ${p}%-16s${r} %s\n" \
    "miyabi"        "ssh to miyabi (starloop:2233)" \
    "oc"            "ssh to Oracle server (opc@ORACLE_IP)" \
    "debian13"      "shell in the Debian 13 container" \
    "ct <name>"     "shell in any Incus container (tab-completes)" \
    "lab"           "menu: containers & VMs" \
    "net"           "menu: Wi-Fi / LAN / WireGuard" \
    "nightlight"    "menu: night light off / auto / on, warmth, monitors   ${d}(nightlight toggle)${r}" \
    "wgup / wgdown" "WireGuard on / off   ${d}(wgs = status)${r}" \
    "nrs / nrb"     "NixOS rebuild now / on next boot" \
    "upd"           "check updates: flake + flatpak, preview & apply (upd -c = check only)" \
    "weather"       "forecast for Nonthaburi" \
    "clock"         "big terminal clock" \
    "vis"           "music visualiser (cava)" \
    "matrix"        "hacker rain   ${d}(also: bonsai, pipes)${r}" \
    "hw / temps"    "live temps, load, GPU, disks"   \
    "clean"         "free disk space: nix, flatpak, podman, docker, incus, caches (clean -n = dry run)" \
    "sys / ff"      "btop / fastfetch" \
    "keys"          "the full shortcut book (Super+? as a pop-up)"
  print ""
}
