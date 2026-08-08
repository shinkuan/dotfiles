#!/usr/bin/env bash
#
# theme.postHook for caelestia-cli.
#
# Under a lua Hyprland config the cli only writes scheme/current.lua, but
# hyprlock speaks hyprlang and sources scheme/current.conf. Regenerate the
# conf from the lua module after every theme change so hyprlock colours
# keep following the scheme.

lua="$HOME/.config/hypr/scheme/current.lua"
conf="$HOME/.config/hypr/scheme/current.conf"

[ -f "$lua" ] || exit 0
sed -n 's/^ *\([A-Za-z_0-9]*\) *= *"\([0-9a-fA-F]*\)",*$/$\1 = \2/p' "$lua" > "$conf"
