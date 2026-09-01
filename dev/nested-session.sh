#!/usr/bin/env bash
# Launch a nested Hyprland running THIS worktree's config, isolated from the
# live session: XDG_CONFIG_HOME points into the worktree, and state/cache go
# to throwaway /tmp dirs so nothing leaks into the live environment.
#
# Run it from a terminal inside the live session. To get shortcuts through to
# the nested window, toggle the outer session's escape submap (SUPER+F12,
# defined in the outer per-machine config) before interacting, and toggle it
# again after leaving.
#
# Always goes through start-hyprland (the watchdog wrapper shipped with
# Hyprland); everything after -- is passed to Hyprland as-is.
set -euo pipefail

REPO_ROOT="$(realpath "$(dirname "$(realpath "$0")")/..")"
CONFIG="$REPO_ROOT/.config/hypr/hyprland.lua"
NAME="$(basename "$REPO_ROOT")"

[[ -f "$CONFIG" ]] || { echo "error: config not found: $CONFIG" >&2; exit 1; }

# local.lua is gitignored (per-machine overrides), so a fresh worktree will
# not have one — seed a minimal file for the nested session first.
if [[ ! -f "$REPO_ROOT/.config/hypr/hyprland/local.lua" ]]; then
    echo "warn: .config/hypr/hyprland/local.lua is missing in this worktree." >&2
    echo "      Nested sessions want a minimal one (no machine daemons);" >&2
    echo "      see local.lua.example." >&2
fi

# Until Phase 5 the nested session still autostarts the caelestia shell.
# Without a cli.json it falls back to defaults, which apply themes globally —
# including OSC colour sequences written to EVERY /dev/pts, i.e. it restains
# the outer session's open terminals. Seed a config with all theme outputs
# disabled (gitignored, like the other worktree seeds).
if [[ ! -f "$REPO_ROOT/.config/caelestia/cli.json" ]]; then
    echo "seeding .config/caelestia/cli.json (all theme outputs disabled)" >&2
    mkdir -p "$REPO_ROOT/.config/caelestia"
    printf '{\n    "theme": {\n' > "$REPO_ROOT/.config/caelestia/cli.json"
    for key in Term Hypr Discord Spicetify Pandora Fuzzel Btop Nvtop Htop \
               Gtk Qt Warp Chromium Zed Cava; do
        printf '        "enable%s": false,\n' "$key"
    done | sed '$ s/,$//' >> "$REPO_ROOT/.config/caelestia/cli.json"
    printf '    }\n}\n' >> "$REPO_ROOT/.config/caelestia/cli.json"
fi

export XDG_CONFIG_HOME="$REPO_ROOT/.config"
export XDG_STATE_HOME="/tmp/$USER-$NAME-state"
export XDG_CACHE_HOME="/tmp/$USER-$NAME-cache"
mkdir -p "$XDG_STATE_HOME" "$XDG_CACHE_HOME"

echo "nested session: config=$CONFIG"
echo "  XDG_CONFIG_HOME=$XDG_CONFIG_HOME"
echo "  XDG_STATE_HOME=$XDG_STATE_HOME"
echo "  XDG_CACHE_HOME=$XDG_CACHE_HOME"

exec start-hyprland -- -c "$CONFIG" "$@"
