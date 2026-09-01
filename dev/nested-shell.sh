#!/usr/bin/env bash
# Run the desktop shell (or any command) against the newest nested Hyprland
# instance with this worktree's XDG isolation, matching nested-session.sh.
#
#   dev/nested-shell.sh                 # start `qs -c desktop` (foreground)
#   dev/nested-shell.sh ipc call bar toggle
#   dev/nested-shell.sh -- grim shot.png
#   HYPR_SIG=<signature> dev/nested-shell.sh ...   # pick an instance explicitly
set -euo pipefail

REPO_ROOT="$(realpath "$(dirname "$(realpath "$0")")/..")"
NAME="$(basename "$REPO_ROOT")"
RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

sig="${HYPR_SIG:-}"
if [[ -z $sig ]]; then
    # newest instance that is not the one this terminal belongs to
    for d in $(ls -t "$RUNTIME/hypr/"); do
        [[ -S "$RUNTIME/hypr/$d/.socket.sock" ]] || continue
        [[ $d == "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && continue
        sig="$d"
        break
    done
fi
[[ -n $sig ]] || { echo "error: no nested Hyprland instance found" >&2; exit 1; }

wl="$(hyprctl instances -j | python3 -c 'import json,sys;s=sys.argv[1];print(next((i["wl_socket"] for i in json.load(sys.stdin) if i["instance"]==s),""))' "$sig")"
[[ -n $wl ]] || { echo "error: instance $sig has no wayland socket" >&2; exit 1; }

export WAYLAND_DISPLAY="$wl"
export HYPRLAND_INSTANCE_SIGNATURE="$sig"
export XDG_CONFIG_HOME="$REPO_ROOT/.config"
export XDG_STATE_HOME="/tmp/$USER-$NAME-state"
export XDG_CACHE_HOME="/tmp/$USER-$NAME-cache"
export PATH="$REPO_ROOT/.local/bin:$PATH"

if [[ $# -eq 0 ]]; then
    exec qs -c desktop
elif [[ $1 == "--" ]]; then
    shift
    exec "$@"
else
    exec qs -c desktop "$@"
fi
