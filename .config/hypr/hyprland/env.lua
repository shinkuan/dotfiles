-- ================================ --
-- Environment Variables
-- ================================ --
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE",    "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

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

-- fcitx5 input method
-- hl.env("GTK_IM_MODULE", "fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("XMODIFIERS",   "@im=fcitx")

-- Quickshell (caelestia)
hl.env("QSG_RENDER_LOOP", "threaded")
