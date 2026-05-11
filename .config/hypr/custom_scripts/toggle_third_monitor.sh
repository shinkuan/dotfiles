#!/bin/bash

# Toggle third monitor on/off
# First grep `hyprctl monitors` to find whether HDMI-A-1 is connected
if hyprctl monitors | grep -q "HDMI-A-1"; then
    # If HDMI-A-1 is connected, turn it off
    hyprctl keyword monitor "HDMI-A-1, disabled"
else
    # If HDMI-A-1 is not connected, turn it on
    hyprctl keyword monitor "HDMI-A-1, 2560x1440@120Hz, 2560x0, 1"
fi