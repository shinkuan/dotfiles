-- ================================ --
-- Autostart
-- ================================ --
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

hl.on("hyprland.start", function()
    -- Input method
    hl.exec_cmd("fcitx5")

    -- Secrets (the polkit agent is the shell's own; see polkit-fallback)
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")

    -- Forward bluetooth media commands to MPRIS
    hl.exec_cmd("mpris-proxy")

    -- Clipboard history (text + images)
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Shell, idle daemon and controller watcher run as user services so a
    -- crash only costs a restart. Skipped in nested sessions (WAYLAND_DISPLAY
    -- is only inherited inside another compositor), where the shell under
    -- test is started by hand and the session must not lock.
    if not os.getenv("WAYLAND_DISPLAY") then
        hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE"
            .. " XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP XDG_CONFIG_HOME"
            .. " && systemctl --user restart desktop-shell.service hypridle.service joystick-idle-watch.service")
        hl.exec_cmd("hyprlock")
    end

    -- Tray applets
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("arch-update --tray")

    -- Machine-specific daemons (sunshine, lan-mouse, ...) live in local.lua.

    -- 2D workspace is now handled in-config by kgrid.lua — no hyprkool daemon.

    -- hyprpaper stays installed as a fallback; the shell paints the wallpaper.
end)
