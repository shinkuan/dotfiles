#!/usr/bin/env sh

set -eu

: "${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR is not set}"
: "${HYPRLAND_INSTANCE_SIGNATURE:?HYPRLAND_INSTANCE_SIGNATURE is not set}"

here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
runtime="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE"
state_file="$runtime/darkwindow-shader-enabled"
marker="$runtime/darkwindow-unavailable"
so="/var/cache/hyprpm/$(id -un)/Hypr-DarkWindow/Hypr-DarkWindow.so"

if [ -e "$state_file" ]; then
    # Currently on -> turn it off (always allowed).
    rm -f -- "$state_file"
else
    # Currently off -> turn it on, but only if the hyprpm plugin is usable.
    # Re-check compatibility from on-disk state first (no rebuild, no prompt):
    # this refreshes the marker so a stale one from login doesn't keep blocking
    # a plugin that has since been fixed. darkwindow_hyprpm_sync.sh sets the
    # marker when the plugin can't build for the running Hyprland.
    "$here/darkwindow_hyprpm_sync.sh" check 2>/dev/null || true
    if [ -e "$marker" ] || [ ! -f "$so" ]; then
        notify-send -a "Hypr-DarkWindow" "無法啟用" \
            "plugin 目前不可用（尚未針對此 Hyprland 版本 build）。請稍候，或執行 hyprpm update。" 2>/dev/null || true
        exit 0
    fi
    touch "$state_file"
fi

hyprctl reload config-only
