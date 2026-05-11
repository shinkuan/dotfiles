#!/bin/bash

# Define the Rofi theme (optional, adjust as you like)
# ROFI_THEME="dmenu" # or "nord", "gruvbox", "Adapta", etc.

# Get the current default sink name
current_default_sink=$(pactl info | grep 'Default Sink:' | awk '{print $3}')

# Get a list of all sink names and their descriptions
# We need both for a user-friendly display in Rofi
# Store them in an associative array for easy lookup
declare -A sink_names_to_descriptions
declare -A sink_descriptions_to_names
sink_list_for_rofi=""

# Use pactl list sinks to get detailed information
# and parse it to get name and description
while IFS= read -r line; do
    if [[ "$line" =~ "Sink #" ]]; then
        sink_id=$(echo "$line" | awk '{print $2}' | tr -d '#')
    elif [[ "$line" =~ "Name:" ]]; then
        sink_name=$(echo "$line" | awk '{print $2}' | tr -d '<>')
    elif [[ "$line" =~ "Description:" ]]; then
        sink_description=$(echo "$line" | cut -d':' -f2- | sed 's/^[[:space:]]*//')

        # Store mappings
        sink_names_to_descriptions["$sink_name"]="$sink_description"
        sink_descriptions_to_names["$sink_description"]="$sink_name"

        # Add to Rofi list, marking the default
        if [[ "$sink_name" == "$current_default_sink" ]]; then
            sink_list_for_rofi+="$sink_description (Current)\n"
        else
            sink_list_for_rofi+="$sink_description\n"
        fi
    fi
done < <(pactl list sinks)

# Use Rofi to select the sink
# -dmenu: Use dmenu mode for selection
# -i: Case-insensitive searching
# -p: Prompt text
# -format f: Use the theme named 'f'
selected_description_with_marker=$(echo -e "$sink_list_for_rofi" | rofi -dmenu -i -p "Select Audio Output")

# Remove the "(Current)" marker if present to get the clean description
selected_description=$(echo "$selected_description_with_marker" | sed 's/ (Current)//')

# Find the sink name corresponding to the selected description
selected_sink_name="${sink_descriptions_to_names[$selected_description]}"

# Check if a selection was made and if it's a valid sink
if [[ -n "$selected_sink_name" ]]; then
    # Set the selected sink as default
    pactl set-default-sink "$selected_sink_name"
    notify-send "Audio Output Changed" "Switched to: $selected_description"
else
    # User cancelled or no valid selection
    notify-send "Audio Output" "Selection cancelled or no valid device chosen."
fi

