-- ================================ --
-- General / Decoration / Animations / Input / Misc
-- ================================ --
-- See https://wiki.hypr.land/Configuring/Basics/Variables/

local C = require("hyprland.scheme")

-- Helper for rgba("XXXXXX" .. alpha) style colors.
local function rgba(hex, alpha)
    return "rgba(" .. (hex or "ffffff") .. (alpha or "ff") .. ")"
end

hl.config({
    -- -------------------------------- --
    -- Look and feel
    -- -------------------------------- --
    general = {
        gaps_in         = 5,
        gaps_out        = 20,
        gaps_workspaces = 20,
        border_size     = 2,
        col = {
            active_border = {
                colors = { rgba(C.primary, "ff"), rgba(C.secondary, "ff") },
                angle  = 45,
            },
            inactive_border = rgba(C.onPrimary, "ff"),
        },
        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        -- dim_inactive = false,
        -- dim_strength = 0.1,
        dim_special = 0.6,

        shadow = {
            enabled      = false,
            range        = 5,
            render_power = 3,
            color        = rgba(C.onPrimary, "aa"),
        },

        blur = {
            enabled            = true,
            xray               = false,
            special            = false,
            new_optimizations  = true,
            size               = 12,
            passes             = 3,
            noise              = 0.05,
            contrast           = 1,
            brightness         = 0.6,
            vibrancy           = 0.0,
            vibrancy_darkness  = 0.0,
            popups             = false,
            popups_ignorealpha = 0.6,
            ignore_opacity     = true,
        },
    },

    -- -------------------------------- --
    -- Layouts
    -- -------------------------------- --
    -- Note: `pseudotile = true` was removed in 0.55 — pseudotile is now only
    -- a dispatcher (`hl.dsp.window.pseudo()`), no longer a config flag.
    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    -- -------------------------------- --
    -- Misc
    -- -------------------------------- --
    misc = {
        -- vrr = 1,
        force_default_wallpaper = 0,    -- set to 0/1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = true, -- disables the random hyprland logo / anime girl background
        middle_click_paste      = false,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms  = true,
        focus_on_activate       = true,
    },

    -- -------------------------------- --
    -- Input
    -- -------------------------------- --
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        -- scroll_factor = 8.0,

        sensitivity = -0.6, -- -1.0 .. 1.0, 0 = no modification

        numlock_by_default = true,

        touchpad = {
            natural_scroll = false,
        },
    },

    -- -------------------------------- --
    -- Debug
    -- -------------------------------- --
    debug = {
        disable_logs = false,
        disable_time = false,
    },
})

-- -------------------------------- --
-- Animations
-- -------------------------------- --
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/

hl.config({
    animations = { enabled = true },
})

-- Curves
hl.curve("specialWorkSwitch", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1,  1    } } })
hl.curve("emphasizedAccel",   { type = "bezier", points = { { 0.3,  0   }, { 0.8,  0.15 } } })
hl.curve("emphasizedDecel",   { type = "bezier", points = { { 0.05, 0.7 }, { 0.1,  1    } } })
hl.curve("standard",          { type = "bezier", points = { { 0.2,  0   }, { 0,    1    } } })

-- Animations
hl.animation({ leaf = "layersIn",        enabled = true, speed = 5,   bezier = "emphasizedDecel", style = "slide" })
hl.animation({ leaf = "layersOut",       enabled = true, speed = 4,   bezier = "emphasizedAccel", style = "slide" })
hl.animation({ leaf = "fadeLayers",      enabled = true, speed = 2.5, bezier = "standard" })

hl.animation({ leaf = "windowsIn",       enabled = true, speed = 5,   bezier = "emphasizedDecel" })
hl.animation({ leaf = "windowsOut",      enabled = true, speed = 3,   bezier = "emphasizedAccel" })
hl.animation({ leaf = "windowsMove",     enabled = true, speed = 6,   bezier = "standard" })
hl.animation({ leaf = "workspaces",      enabled = true, speed = 5,   bezier = "standard" })

hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4,  bezier = "specialWorkSwitch", style = "slidefadevert 15%" })

hl.animation({ leaf = "fade",            enabled = true, speed = 6,   bezier = "standard" })
hl.animation({ leaf = "fadeDim",         enabled = true, speed = 6,   bezier = "standard" })
hl.animation({ leaf = "border",          enabled = true, speed = 6,   bezier = "standard" })

hl.animation({ leaf = "zoomFactor",      enabled = true, speed = 2,   bezier = "standard" })

-- -------------------------------- --
-- Workspace rules (smart gaps examples, disabled)
-- -------------------------------- --
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({ name = "no-gaps-wtv1", match = { float = false, workspace = "w[tv1]" }, border_size = 0, rounding = 0 })
-- hl.window_rule({ name = "no-gaps-f1",   match = { float = false, workspace = "f[1]"   }, border_size = 0, rounding = 0 })

-- -------------------------------- --
-- Example per-device input config (disabled)
-- -------------------------------- --
-- hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })

-- -------------------------------- --
-- Gestures (disabled)
-- -------------------------------- --
-- hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
