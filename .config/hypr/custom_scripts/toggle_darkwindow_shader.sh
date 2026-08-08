#!/usr/bin/env sh

set -eu

: "${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR is not set}"
: "${HYPRLAND_INSTANCE_SIGNATURE:?HYPRLAND_INSTANCE_SIGNATURE is not set}"

state_file="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/darkwindow-shader-enabled"

if [ -e "$state_file" ]; then
    rm -f -- "$state_file"
else
    touch "$state_file"
fi

hyprctl reload config-only
