#!/bin/bash

echo $WALLPAPER_PATH
hellwal -i "$WALLPAPER_PATH" --check-contrast "$@"
# mkdir -p "$HOME/.local/state/caelestia"
# cp "$HOME/.cache/hellwal/sequences.txt" "$HOME/.local/state/caelestia/sequences.txt"

hyprctl reload
