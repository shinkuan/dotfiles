#!/usr/bin/env sh
# Hyprland 0.55+ replaced `hyprctl keyword` with Lua config updates via
# `hyprctl eval` (which runs an arbitrary Lua snippet inside the compositor).
# `getoption` now uses dotted section.option paths instead of section:option.
HYPRGAMEMODE=$(hyprctl getoption animations.enabled | awk 'NR==1{print $2}')
if [ "$HYPRGAMEMODE" = 1 ] ; then
    hyprctl eval 'hl.config({
        animations = { enabled = false },
        decoration = { shadow = { enabled = false }, blur = { enabled = false }, rounding = 0 },
        general    = { gaps_in = 0, gaps_out = 0, border_size = 1 },
    })'
    # kill quickshell or qs
    pkill -f quickshell
    pkill -f qs
    # Named window rules are toggled via the handle returned by hl.window_rule().
    # Expose the handles in your rules.lua (e.g. `_G.wrules = _G.wrules or {}`
    # and `_G.wrules["windowrule-15"] = hl.window_rule({ name = "windowrule-15", ... })`)
    # before these toggles will succeed.
    hyprctl eval 'if _G.wrules and _G.wrules["windowrule-15"] then _G.wrules["windowrule-15"]:set_enabled(false) end'
    hyprctl eval 'if _G.wrules and _G.wrules["windowrule-16"] then _G.wrules["windowrule-16"]:set_enabled(false) end'
    exit
fi

hyprctl reload
# if quickshell or qs is not running, start it
if ! pgrep -f quickshell >/dev/null && ! pgrep -f qs >/dev/null; then
    exec caelestia shell
    exec qs -c overview -d
    hyprctl eval 'if _G.wrules and _G.wrules["windowrule-15"] then _G.wrules["windowrule-15"]:set_enabled(true) end'
    hyprctl eval 'if _G.wrules and _G.wrules["windowrule-16"] then _G.wrules["windowrule-16"]:set_enabled(true) end'

fi