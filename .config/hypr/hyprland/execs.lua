-- ================================ --
-- Autostart
-- ================================ --
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

hl.on("hyprland.start", function()
    -- Input method
    hl.exec_cmd("fcitx5")

    -- Authentication / secrets / polkit
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

    -- Vicinae launcher
    hl.exec_cmd("env QT_SCALE_FACTOR=1.5 vicinae server")

    -- Forward bluetooth media commands to MPRIS
    hl.exec_cmd("mpris-proxy")

    -- Quickshell (caelestia)
    hl.exec_cmd("QSG_RENDER_LOOP=threaded caelestia shell")
    hl.exec_cmd("QSG_RENDER_LOOP=threaded qs -c overview")
    -- hl.exec_cmd("qs -c quickvoice")

    -- Screen lock
    hl.exec_cmd("hyprlock")

    -- Tray applets
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("arch-update --tray")

    -- Machine-specific daemons (sunshine, lan-mouse, ...) live in local.lua.

    -- 2D workspace is now handled in-config by kgrid.lua — no hyprkool daemon.

    -- Optional / disabled in original config:
    -- hl.exec_cmd("swaync")
    -- hl.exec_cmd("systemctl --user start hyprpolkitagent")
    -- hl.exec_cmd("wl-paste --watch cliphist store")
    -- hl.exec_cmd("hyprpaper")
    -- hl.exec_cmd("waybar")
    -- hl.exec_cmd("trash-empty 30")
    -- hl.exec_cmd("/usr/lib/geoclue-2.0/demos/agent")
    -- hl.exec_cmd("sleep 1 && gammastep")
    -- hl.exec_cmd("sway-audio-idle-inhibit --ignore-source-outputs cava")
    -- hl.exec_cmd("caelestia pip -d")
end)
