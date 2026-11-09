#!/usr/bin/env bash
# Per-screen workspaces: Mod+N goes to slot N on the *focused* screen.
#   DP-1 -> workspaces 1..10   DP-2 -> workspaces 11..20
# usage: ws.sh focus N | ws.sh move N     (N = 1..10)
action=$1 n=$2
out=$(swaymsg -t get_outputs -r | python3 -Ic 'import json,sys; print(next(o["name"] for o in json.load(sys.stdin) if o["focused"]))')
case $out in
  DP-2) ws=$((n + 10)) ;;
  *)    ws=$n ;;
esac
if [ "$action" = move ]; then
  swaymsg "move container to workspace number $ws"
else
  swaymsg "workspace number $ws"
fi
