#!/usr/bin/env sh
# ============================================================================
# Keep the hyprpm-managed Hypr-DarkWindow plugin in sync with Hyprland.
#
# Modes:
#   (default)  full sync: run at login (exec-once via hyprland/rpm.conf).
#   check      re-evaluate compatibility from on-disk state only; never runs
#              `hyprpm update`, never prompts, never notifies. Used by the
#              toggle script so a stale marker can't block a plugin that was
#              fixed mid-session.
#
# It handles the two awkward cases that come up when Hyprland is updated:
#
#   1. Hyprland was updated but hyprpm hasn't rebuilt the plugin yet.
#      -> run `hyprpm update`, which rebuilds the plugin against the running
#         Hyprland. That step writes to /var/cache/hyprpm (root-owned) via
#         `sudo`, and runs with no tty, so SUDO_ASKPASS points at a GUI
#         password popup (gui_askpass.sh). No terminal, no passwordless sudo.
#
#   2. Hyprland was updated and hyprpm ran, but Hypr-DarkWindow does not yet
#      support this Hyprland version (build failed / no matching commit pin).
#      -> do NOT load anything, drop a `darkwindow-unavailable` marker so the
#         toggle script and rpm.lua keep the feature fully off, and notify the
#         user with notify-send.
#
# Compatibility is decided entirely from hyprpm's own state files, so we never
# load a possibly-broken plugin just to probe it. The actual loading + shader
# configuration still happens on demand in rpm.lua when the shader is toggled.
# ============================================================================
set -u

mode="${1:-sync}"

user=$(id -un)
cache="/var/cache/hyprpm/$user"
plugdir="$cache/Hypr-DarkWindow"
so="$plugdir/Hypr-DarkWindow.so"

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export SUDO_ASKPASS="$here/gui_askpass.sh"

# Persistent (survives logout) record of the last Hyprland commit we already
# ran `hyprpm update` for, so a Hyprland version that upstream can't build yet
# doesn't pop a password prompt + recompile on every single login.
statedir="${XDG_CACHE_HOME:-$HOME/.cache}/hypr-darkwindow"
tried_file="$statedir/last-update-commit"

# Per-instance signalling files (tmpfs, cleared on each login).
runtime="${XDG_RUNTIME_DIR:-}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}"
marker="$runtime/darkwindow-unavailable"
state_file="$runtime/darkwindow-shader-enabled"

notify() { notify-send -a "Hypr-DarkWindow" "$1" "${2:-}" 2>/dev/null || true; }

set_unavailable() {
    [ -d "$runtime" ] && : > "$marker" 2>/dev/null
    rm -f -- "$state_file" 2>/dev/null || true   # make sure the feature is off
}
set_available() { rm -f -- "$marker" 2>/dev/null || true; }

# Current Hyprland commit (hyprpm keys its build state on this).
hl_commit=$(hyprctl version 2>/dev/null | grep -oE 'commit [0-9a-f]{40}' | head -1 | cut -d' ' -f2)

read_state() {
    state_commit=$(sed -n "s/^hash = '\([0-9a-f]\{40\}\).*/\1/p" "$cache/state.toml" 2>/dev/null | head -1)
    failed=$(sed -n 's/^failed *= *\([a-z]*\).*/\1/p' "$plugdir/state.toml" 2>/dev/null | head -1)
}

# Plugin is usable iff hyprpm built it for the running Hyprland, the build did
# not fail, and the .so is actually there.
compatible() {
    [ -n "$hl_commit" ] &&
    [ "$state_commit" = "$hl_commit" ] &&
    [ "$failed" = "false" ] &&
    [ -f "$so" ]
}

# --- Fast path: already built for the running Hyprland (silent, no sudo) -----
read_state
if compatible; then
    set_available
    exit 0
fi

# --- check mode: just reflect on-disk reality, never rebuild / prompt --------
if [ "$mode" = check ]; then
    set_unavailable
    exit 0
fi

# --- Can't tell (hyprctl not ready / IPC hiccup): do nothing disruptive ------
# Empty hl_commit means "undecided", not "broken" -> never rebuild on a guess.
if [ -z "$hl_commit" ]; then
    exit 0
fi

# Not compatible for real -> keep the feature off from here on (pessimistic:
# covers the whole rebuild window, so a toggle mid-compile is refused rather
# than loading a stale .so).
set_unavailable

# --- Make sure the plugin is even added/enabled in hyprpm -------------------
if ! hyprpm list 2>/dev/null | grep -q "Hypr-DarkWindow"; then
    notify "Hypr-DarkWindow 未安裝" \
        "請先：hyprpm add https://github.com/micha4w/Hypr-DarkWindow 並 hyprpm enable Hypr-DarkWindow"
    exit 0
fi

# --- Already tried this Hyprland version and it didn't work -> don't nag -----
# Avoids a sudo popup + doomed recompile on every login while upstream lags.
# Cleared implicitly when the commit changes (the value won't match anymore).
if [ "$(cat "$tried_file" 2>/dev/null)" = "$hl_commit" ]; then
    exit 0
fi

# --- Case 1: rebuild for the current Hyprland (GUI sudo popup) --------------
mkdir -p -- "$statedir" 2>/dev/null || true
printf '%s\n' "$hl_commit" > "$tried_file" 2>/dev/null || true
notify "正在更新 Hypr-DarkWindow" \
    "Hyprland 版本有變動，執行 hyprpm update（可能會跳出密碼視窗）…"
hyprpm update >/dev/null 2>&1 || true

read_state
if compatible; then
    set_available
    notify "Hypr-DarkWindow 已更新" "已針對目前的 Hyprland 版本重新編譯完成。"
    # If the shader was left on, re-parse config so rpm.lua loads the fresh .so.
    [ -e "$state_file" ] && hyprctl reload config-only >/dev/null 2>&1 || true
    exit 0
fi

# --- Case 2: plugin can't build for this Hyprland yet ------------------------
set_unavailable
notify "Hypr-DarkWindow 已停用" \
    "plugin 尚未支援目前的 Hyprland 版本（build 失敗／無對應 commit pin），或未完成 sudo 授權。相關功能已停用。"
exit 0
