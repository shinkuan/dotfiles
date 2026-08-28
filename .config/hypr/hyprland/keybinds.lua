-- ================================ --
-- Keybinds
-- ================================ --
-- See https://wiki.hypr.land/Configuring/Basics/Binds/

local V    = require("hyprland.var")
local dsp  = hl.dsp
local bind = hl.bind

-- ============================ --
-- Shell (caelestia)
-- ============================ --
bind("SUPER + Super_L",   dsp.global("caelestia:launcher"),          { release = true })
-- NOTE: Hyprland 0.55 Lua API rejects "catchall" when combined with a
-- modifier (`Unknown keysym: "catchall"`). In the new API `catchall` only
-- works as a standalone keysym inside a submap. The mouse-button binds
-- below still cover dismissal via clicks. If you need keyboard dismissal,
-- consider wrapping the launcher in a dedicated submap that contains a
-- bare `bind("catchall", ...)`.
-- bind("SUPER + catchall",  dsp.global("caelestia:launcherInterrupt"), { release = true })
bind("SUPER + mouse:272", dsp.global("caelestia:launcherInterrupt"), { release = true })
bind("SUPER + mouse:273", dsp.global("caelestia:launcherInterrupt"), { release = true })
bind("SUPER + mouse:274", dsp.global("caelestia:launcherInterrupt"), { release = true })
bind("SUPER + mouse:275", dsp.global("caelestia:launcherInterrupt"), { release = true })
bind("SUPER + mouse:276", dsp.global("caelestia:launcherInterrupt"), { release = true })
bind("SUPER + mouse:277", dsp.global("caelestia:launcherInterrupt"), { release = true })
bind("SUPER + mouse_up",  dsp.global("caelestia:launcherInterrupt"), { release = true })
bind("SUPER + mouse_down",dsp.global("caelestia:launcherInterrupt"), { release = true })

bind("CTRL + ALT + Delete", dsp.global("caelestia:session"))
bind("SUPER + Escape",      dsp.global("caelestia:session"))
bind("CTRL + ALT + C",      dsp.global("caelestia:clearNotifs"))

-- ============================ --
-- Launchers
-- ============================ --
-- vicinae
bind("SUPER + Space", dsp.exec_cmd("vicinae toggle"))

-- rofi
bind("SUPER + B", dsp.exec_cmd(V.menu_kill .. " || " .. V.menu))

-- ============================ --
-- Brightness / Media (caelestia)
-- ============================ --
bind("XF86MonBrightnessUp",   dsp.global("caelestia:brightnessUp"),   { locked = true })
bind("XF86MonBrightnessDown", dsp.global("caelestia:brightnessDown"), { locked = true })

bind("XF86AudioPlay",  dsp.global("caelestia:mediaToggle"),   { locked = true })
bind("XF86AudioPause", dsp.global("caelestia:mediaToggle"),   { locked = true })
bind("XF86AudioNext",  dsp.global("caelestia:mediaNext"),     { locked = true })
bind("XF86AudioPrev",  dsp.global("caelestia:mediaPrevious"), { locked = true })
bind("XF86AudioStop",  dsp.global("caelestia:mediaStop"),     { locked = true })
bind("ALT + XF86AudioPlay", dsp.exec_cmd(V.audio_menu))

-- Reload
bind("CTRL + SUPER + ALT + R", dsp.exec_cmd("hyprctl reload"), { release = true })

-- ============================ --
-- KGrid — 2D workspace (Lua engine, replaces hyprkool; see kgrid.lua)
-- ============================ --
-- Switch activity (lands on that activity's remembered cell)
bind("CTRL + SUPER + Space", function() KGrid.switch_activity("default") end)
bind("CTRL + SUPER + Z",     function() KGrid.switch_activity("Z") end)
bind("CTRL + SUPER + X",     function() KGrid.switch_activity("X") end)
bind("CTRL + SUPER + C",     function() KGrid.switch_activity("C") end)
bind("CTRL + SUPER + A",     function() KGrid.switch_activity("A") end)
bind("CTRL + SUPER + S",     function() KGrid.switch_activity("S") end)
bind("CTRL + SUPER + D",     function() KGrid.switch_activity("D") end)
bind("CTRL + SUPER + Q",     function() KGrid.switch_activity("Q") end)
bind("CTRL + SUPER + W",     function() KGrid.switch_activity("W") end)
bind("CTRL + SUPER + E",     function() KGrid.switch_activity("E") end)

-- Switch activity, taking the active window with you
bind("CTRL + SUPER + SHIFT + Space", function() KGrid.switch_activity("default", true) end)
bind("CTRL + SUPER + SHIFT + Z",     function() KGrid.switch_activity("Z", true) end)
bind("CTRL + SUPER + SHIFT + X",     function() KGrid.switch_activity("X", true) end)
bind("CTRL + SUPER + SHIFT + C",     function() KGrid.switch_activity("C", true) end)
bind("CTRL + SUPER + SHIFT + A",     function() KGrid.switch_activity("A", true) end)
bind("CTRL + SUPER + SHIFT + S",     function() KGrid.switch_activity("S", true) end)
bind("CTRL + SUPER + SHIFT + D",     function() KGrid.switch_activity("D", true) end)
bind("CTRL + SUPER + SHIFT + Q",     function() KGrid.switch_activity("Q", true) end)
bind("CTRL + SUPER + SHIFT + W",     function() KGrid.switch_activity("W", true) end)
bind("CTRL + SUPER + SHIFT + E",     function() KGrid.switch_activity("E", true) end)
    
-- Overview
bind("SUPER + Tab", dsp.exec_cmd("qs ipc -c overview call overview toggle"))
-- quickvoice (SUPER + S) is machine-specific — lives in local.lua

-- Workspace movement within the current activity grid
bind("CTRL + SUPER + left",  function() KGrid.go(-1,  0) end)
bind("CTRL + SUPER + right", function() KGrid.go( 1,  0) end)
bind("CTRL + SUPER + up",    function() KGrid.go( 0, -1) end)
bind("CTRL + SUPER + down",  function() KGrid.go( 0,  1) end)

bind("CTRL + SUPER + SHIFT + left",  function() KGrid.go(-1,  0, true) end)
bind("CTRL + SUPER + SHIFT + right", function() KGrid.go( 1,  0, true) end)
bind("CTRL + SUPER + SHIFT + up",    function() KGrid.go( 0, -1, true) end)
bind("CTRL + SUPER + SHIFT + down",  function() KGrid.go( 0,  1, true) end)

-- Multi-monitor window move (replaces hyprkool next/prev-monitor).
local function move_to_monitor(dir)
    return function()
        local target = hl.get_monitor(dir)
        if target then hl.dispatch(dsp.window.move({ monitor = target })) end
    end
end
local monitor_move_binds = {
    bind("CTRL + SUPER + ALT + left",  move_to_monitor("l")),
    bind("CTRL + SUPER + ALT + right", move_to_monitor("r")),
}

-- `monitor.removed` may fire before hl.get_monitors() drops the monitor (the
-- state tracker is just another listener), so exclude the departing one.
local function sync_monitor_move_binds(removed)
    local n = 0
    for _, m in ipairs(hl.get_monitors()) do
        if not m.is_mirror and not (removed and m.id == removed.id) then
            n = n + 1
        end
    end
    for _, kb in ipairs(monitor_move_binds) do kb:set_enabled(n > 1) end
end

sync_monitor_move_binds()  -- on reload the monitors already exist
hl.on("monitor.added",          function()  sync_monitor_move_binds()  end) -- startup + hotplug
hl.on("monitor.removed",        function(m) sync_monitor_move_binds(m) end)
hl.on("monitor.layout_changed", function()  sync_monitor_move_binds()  end) -- mirror changes

-- ============================ --
-- Window cycling
-- ============================ --
bind("ALT + Tab", function()
    hl.dispatch(dsp.window.cycle_next())
    hl.dispatch(dsp.window.alter_zorder({ mode = "top" }))
end)
bind("SHIFT + ALT + Tab", function()
    hl.dispatch(dsp.window.cycle_next({ next = false }))
    hl.dispatch(dsp.window.alter_zorder({ mode = "top" }))
end)

-- ============================ --
-- Window actions
-- ============================ --
-- Focus + raise
bind("SUPER + left",  function()
    hl.dispatch(dsp.focus({ direction = "left" }))
    hl.dispatch(dsp.window.alter_zorder({ mode = "top" }))
end)
bind("SUPER + right", function()
    hl.dispatch(dsp.focus({ direction = "right" }))
    hl.dispatch(dsp.window.alter_zorder({ mode = "top" }))
end)
bind("SUPER + up",    function()
    hl.dispatch(dsp.focus({ direction = "up" }))
    hl.dispatch(dsp.window.alter_zorder({ mode = "top" }))
end)
bind("SUPER + down",  function()
    hl.dispatch(dsp.focus({ direction = "down" }))
    hl.dispatch(dsp.window.alter_zorder({ mode = "top" }))
end)

-- Move window
bind("SUPER + SHIFT + left",  dsp.window.move({ direction = "left" }))
bind("SUPER + SHIFT + right", dsp.window.move({ direction = "right" }))
bind("SUPER + SHIFT + up",    dsp.window.move({ direction = "up" }))
bind("SUPER + SHIFT + down",  dsp.window.move({ direction = "down" }))

-- Split ratio (dwindle) — native Lua layout message in 0.55
bind("SUPER + minus", dsp.layout("splitratio -0.1"), { repeating = true })
bind("SUPER + equal", dsp.layout("splitratio +0.1"), { repeating = true })

-- Mouse drag / resize
bind("SUPER + mouse:272", dsp.window.drag(),   { mouse = true })
bind("SUPER + mouse:273", dsp.window.resize(), { mouse = true })
bind("SUPER + X",         dsp.window.resize(), { mouse = true })

-- Center / resize-to-percent
bind("CTRL + SUPER + Backslash", dsp.window.center())
bind("CTRL + SUPER + ALT + Backslash", function()
    -- 0.55: use the native Lua dispatcher instead of shelling out to hyprctl
    hl.dispatch(dsp.window.resize({ x = "55%", y = "70%" }))
    hl.dispatch(dsp.window.center())
end)

-- Picture-in-picture (caelestia)
bind("SUPER + ALT + P", dsp.exec_cmd("caelestia pip"))

-- Pin / fullscreen / float / kill / exit
bind("SUPER + P",         dsp.window.pin())
bind("SUPER + F",         dsp.window.fullscreen({ mode = "fullscreen" }))
bind("SUPER + ALT + F",   dsp.window.fullscreen({ mode = "maximized"  })) -- fullscreen with borders
bind("SUPER + ALT + Space", dsp.window.float({ action = "toggle" }))
bind("SUPER + Q",         dsp.window.close())
bind("SUPER + SHIFT + M",       dsp.exit())
bind("CTRL + SUPER + SHIFT + M",dsp.exit())

-- Zoom (hold-to-zoom)
-- 0.55: `hyprctl keyword` is gone; mutate config directly via hl.config().
bind("SUPER + Z", function() hl.config({ cursor = { zoom_factor = 3.0 } }) end)
bind("SUPER + Z", function() hl.config({ cursor = { zoom_factor = 1.0 } }) end, { release = true })

-- ============================ --
-- Apps
-- ============================ --
bind("SUPER + T",       dsp.exec_cmd("app2unit -- foot"))
bind("SUPER + E",       dsp.exec_cmd("nautilus --new-window"))
bind("SUPER + ALT + E", dsp.exec_cmd("app2unit -- nemo"))
bind("CTRL + SUPER + Slash",
        dsp.exec_cmd("pkill fuzzel || fuzzel --launch-prefix='app2unit --fuzzel-compat -- '"))

-- ============================ --
-- Screenshots / colour picker
-- ============================ --
bind("Print",                  dsp.exec_cmd("caelestia screenshot"), { locked = true })
bind("SUPER + SHIFT + S",      dsp.global("caelestia:screenshotFreeze"))     -- 凍結選區 → 開 satty
bind("SUPER + SHIFT + ALT + S",dsp.global("caelestia:screenshotFreezeClip")) -- 凍結選區 → 直接進剪貼簿
bind("SUPER + SHIFT + C",      dsp.exec_cmd("hyprpicker -a"))

-- ============================ --
-- Volume
-- ============================ --
bind("XF86AudioMute",        dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
bind("SUPER + SHIFT + M",    dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
bind("XF86AudioRaiseVolume", dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 10%+"), { locked = true, repeating = true })
bind("XF86AudioLowerVolume", dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-"),     { locked = true, repeating = true })

-- ============================ --
-- Power / lock
-- ============================ --
bind("CTRL + SHIFT + ALT + Delete", dsp.exec_cmd("pkill wlogout || wlogout -p layer-shell"))
bind("SUPER + L",                   dsp.exec_cmd("pidof hyprlock || hyprlock"))
bind("SUPER + SHIFT + L",           dsp.exec_cmd("pidof hyprlock || hyprlock"))
bind("CTRL + SUPER + SHIFT + L",
        dsp.exec_cmd("sleep 1 && (pidof hyprlock || hyprlock) & sleep 2 && hyprctl dispatch 'hl.dsp.dpms({ action = \"disable\" })'"))

-- ============================ --
-- Clipboard
-- ============================ --
bind("SUPER + V", dsp.exec_cmd("vicinae vicinae://launch/clipboard/history"))

-- ============================ --
-- Misc utilities
-- ============================ --
-- Toggle keybind grabbing (for apps that want to grab shortcuts)
-- 0.55: shell out to read the current value, then mutate via hl.config()
-- inside `hyprctl eval`. Note: `getoption` paths use dots now (section.option).
bind("CTRL + ALT + Z", function()
    hl.exec_cmd([[hyprctl eval "hl.config({ binds = { disable_keybind_grabbing = $(hyprctl getoption binds.disable_keybind_grabbing -j | jq -r '.int == 0') } })"]])
end)

-- Game Mode
bind("SUPER + ALT + G", dsp.exec_cmd(V.gamemode_toggle))

-- Waifuland
bind("SUPER + ALT + W",        dsp.exec_cmd("killall -s SIGUSR1 waifuland"))
bind("CTRL + SUPER + ALT + W", dsp.exec_cmd("killall -s SIGUSR2 waifuland"))

-- Sunshine
bind("SUPER + ALT + S", dsp.exec_cmd("pkill sunshine || ~/.local/bin/sunshine.sh"))

-- Toggle third monitor
bind("SUPER + ALT + T", dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/custom_scripts/toggle_third_monitor.sh"))

-- Test notification
bind("SUPER + ALT + F12",
        dsp.exec_cmd("notify-send -u low -i dialog-information-symbolic 'Test notification' \"Here's a really long message to test truncation and wrapping\\nYou can middle click or flick this notification to dismiss it!\" -a 'Shell' -A \"Test1=I got it!\" -A \"Test2=Another action\""))
