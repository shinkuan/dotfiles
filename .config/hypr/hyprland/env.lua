-- ================================ --
-- Environment Variables
-- ================================ --
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE",    "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Some config-file consumers (e.g. fastfetch) expand env vars but have no
-- XDG fallback of their own, so export the resolved value.
hl.env("XDG_CONFIG_HOME", require("hyprland.util").config_home())

-- HiDPI
hl.env("GDK_SCALE", "1")
hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})

-- NVIDIA
hl.env("LIBVA_DRIVER_NAME",            "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME",    "nvidia")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("NVD_BACKEND",                  "direct")

-- Qt
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QSG_RENDER_LOOP", "threaded")

-- fcitx5 input method
-- hl.env("GTK_IM_MODULE", "fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("XMODIFIERS",   "@im=fcitx")

-- Quickshell
hl.env("QSG_RENDER_LOOP", "threaded")
