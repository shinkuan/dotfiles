-- ================================ --
-- Keybinds
-- ================================ --
-- See https://wiki.hypr.land/Configuring/Basics/Binds/

local V    = require("hyprland.var")
local dsp  = hl.dsp
local bind = hl.bind

-- Activate the "global" submap on startup AND on every config reload.
-- caelestia binds rely on this submap being active. This mirrors the old
-- config's `exec = hyprctl dispatch submap global` (which fires per-reload).
local function activate_global_submap()
    hl.dispatch(dsp.submap("global"))
end
hl.on("hyprland.start",   activate_global_submap)
hl.on("config.reloaded",  activate_global_submap)

hl.define_submap("global", function()

    -- ============================ --
    -- Shell (caelestia)
    -- ============================ --
    bind("SUPER + Super_L",   dsp.global("caelestia:launcher"),          { ignore_mods = true, release = true })
    bind("SUPER + catchall",  dsp.global("caelestia:launcherInterrupt"), { ignore_mods = true, non_consuming = true })
    bind("SUPER + mouse:272", dsp.global("caelestia:launcherInterrupt"), { ignore_mods = true, non_consuming = true })
    bind("SUPER + mouse:273", dsp.global("caelestia:launcherInterrupt"), { ignore_mods = true, non_consuming = true })
    bind("SUPER + mouse:274", dsp.global("caelestia:launcherInterrupt"), { ignore_mods = true, non_consuming = true })
    bind("SUPER + mouse:275", dsp.global("caelestia:launcherInterrupt"), { ignore_mods = true, non_consuming = true })
    bind("SUPER + mouse:276", dsp.global("caelestia:launcherInterrupt"), { ignore_mods = true, non_consuming = true })
    bind("SUPER + mouse:277", dsp.global("caelestia:launcherInterrupt"), { ignore_mods = true, non_consuming = true })
    bind("SUPER + mouse_up",  dsp.global("caelestia:launcherInterrupt"), { ignore_mods = true, non_consuming = true })
    bind("SUPER + mouse_down",dsp.global("caelestia:launcherInterrupt"), { ignore_mods = true, non_consuming = true })

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
    -- hyprkool — switch activity
    -- ============================ --
    bind("CTRL + SUPER + Space", dsp.exec_cmd("hyprkool switch-to-activity -n default"))
    bind("CTRL + SUPER + Z",     dsp.exec_cmd("hyprkool switch-to-activity -n Z"))
    bind("CTRL + SUPER + X",     dsp.exec_cmd("hyprkool switch-to-activity -n X"))
    bind("CTRL + SUPER + C",     dsp.exec_cmd("hyprkool switch-to-activity -n C"))
    bind("CTRL + SUPER + A",     dsp.exec_cmd("hyprkool switch-to-activity -n A"))
    bind("CTRL + SUPER + S",     dsp.exec_cmd("hyprkool switch-to-activity -n S"))
    bind("CTRL + SUPER + D",     dsp.exec_cmd("hyprkool switch-to-activity -n D"))
    bind("CTRL + SUPER + Q",     dsp.exec_cmd("hyprkool switch-to-activity -n Q"))
    bind("CTRL + SUPER + W",     dsp.exec_cmd("hyprkool switch-to-activity -n W"))
    bind("CTRL + SUPER + E",     dsp.exec_cmd("hyprkool switch-to-activity -n E"))

    -- hyprkool — switch activity, taking the active window with you
    bind("CTRL + SUPER + SHIFT + Space", dsp.exec_cmd("hyprkool switch-to-activity -w -n default"))
    bind("CTRL + SUPER + SHIFT + Z",     dsp.exec_cmd("hyprkool switch-to-activity -w -n Z"))
    bind("CTRL + SUPER + SHIFT + X",     dsp.exec_cmd("hyprkool switch-to-activity -w -n X"))
    bind("CTRL + SUPER + SHIFT + C",     dsp.exec_cmd("hyprkool switch-to-activity -w -n C"))
    bind("CTRL + SUPER + SHIFT + A",     dsp.exec_cmd("hyprkool switch-to-activity -w -n A"))
    bind("CTRL + SUPER + SHIFT + S",     dsp.exec_cmd("hyprkool switch-to-activity -w -n S"))
    bind("CTRL + SUPER + SHIFT + D",     dsp.exec_cmd("hyprkool switch-to-activity -w -n D"))
    bind("CTRL + SUPER + SHIFT + Q",     dsp.exec_cmd("hyprkool switch-to-activity -w -n Q"))
    bind("CTRL + SUPER + SHIFT + W",     dsp.exec_cmd("hyprkool switch-to-activity -w -n W"))
    bind("CTRL + SUPER + SHIFT + E",     dsp.exec_cmd("hyprkool switch-to-activity -w -n E"))

    -- hyprkool — overview & voice
    bind("SUPER + Tab", dsp.exec_cmd("qs ipc -c overview call overview toggle"))
    bind("SUPER + S",   dsp.exec_cmd("qs ipc -c quickvoice call quickvoice start"))

    -- hyprkool — workspace movement
    bind("CTRL + SUPER + left",  dsp.exec_cmd("hyprkool move-left"))
    bind("CTRL + SUPER + right", dsp.exec_cmd("hyprkool move-right"))
    bind("CTRL + SUPER + up",    dsp.exec_cmd("hyprkool move-up"))
    bind("CTRL + SUPER + down",  dsp.exec_cmd("hyprkool move-down"))

    bind("CTRL + SUPER + SHIFT + left",  dsp.exec_cmd("hyprkool move-left -w"))
    bind("CTRL + SUPER + SHIFT + right", dsp.exec_cmd("hyprkool move-right -w"))
    bind("CTRL + SUPER + SHIFT + up",    dsp.exec_cmd("hyprkool move-up -w"))
    bind("CTRL + SUPER + SHIFT + down",  dsp.exec_cmd("hyprkool move-down -w"))

    bind("CTRL + SUPER + ALT + left",  dsp.exec_cmd("hyprkool next-monitor -c -w"))
    bind("CTRL + SUPER + ALT + right", dsp.exec_cmd("hyprkool prev-monitor -c -w"))

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

    -- Split ratio (dwindle)
    bind("SUPER + minus", dsp.exec_cmd("hyprctl dispatch splitratio -0.1"), { repeating = true })
    bind("SUPER + equal", dsp.exec_cmd("hyprctl dispatch splitratio 0.1"),  { repeating = true })

    -- Mouse drag / resize
    bind("SUPER + mouse:272", dsp.window.drag(),   { mouse = true })
    bind("SUPER + mouse:273", dsp.window.resize(), { mouse = true })
    bind("SUPER + X",         dsp.window.resize(), { mouse = true })

    -- Center / resize-to-percent
    bind("CTRL + SUPER + Backslash", dsp.window.center())
    bind("CTRL + SUPER + ALT + Backslash", function()
        hl.dispatch(dsp.exec_cmd("hyprctl dispatch resizeactive exact 55% 70%"))
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
    bind("SUPER + Z", dsp.exec_cmd("hyprctl keyword cursor:zoom_factor 3.0"))
    bind("SUPER + Z", dsp.exec_cmd("hyprctl keyword cursor:zoom_factor 1.0"), { release = true })

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
    bind("SUPER + SHIFT + S",      dsp.global("caelestia:screenshotFreezeClip"))
    bind("SUPER + SHIFT + ALT + S",dsp.global("caelestia:screenshot"))
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
    bind("SUPER + L",                   dsp.exec_cmd("hyprlock"))
    bind("SUPER + SHIFT + L",           dsp.exec_cmd("hyprlock"))
    bind("CTRL + SUPER + SHIFT + L",
         dsp.exec_cmd("sleep 1 && hyprlock & sleep 2 && hyprctl dispatch dpms off"))

    -- ============================ --
    -- Clipboard
    -- ============================ --
    bind("SUPER + V", dsp.exec_cmd("vicinae vicinae://launch/clipboard/history"))

    -- ============================ --
    -- Misc utilities
    -- ============================ --
    -- Toggle keybind grabbing (for apps that want to grab shortcuts)
    bind("CTRL + ALT + Z",
         dsp.exec_cmd("hyprctl keyword binds:disable_keybind_grabbing $(hyprctl getoption binds:disable_keybind_grabbing -j | jq -r '.int == 0')"))

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

end)
