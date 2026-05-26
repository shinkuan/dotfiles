-- ================================ --
-- Window & Layer Rules
-- ================================ --
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
--
-- Note: rules are evaluated top-to-bottom. Named rules take precedence
-- over anonymous ones.

-- Ignore maximize requests from apps.
hl.window_rule({
    name           = "windowrule-1",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland.
hl.window_rule({
    name  = "windowrule-2",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- yad dialog
-- Note: `max_size` is now `vec2` (numbers only — no monitor_w/h expressions).
-- We use `size` instead, which accepts string expressions per the wiki.
hl.window_rule({
    name   = "windowrule-3",
    match  = { class = "^(yad)$" },
    float  = true,
    size   = { "monitor_w*0.5", "monitor_h*0.5" },
    center = true,
})

-- Edge case: empty class + empty title
hl.window_rule({
    name        = "edge-fuck-you-1",
    match       = { class = "^$", title = "^$" },
    float       = true,
    no_anim     = true,
    no_focus    = true,
    border_size = 0,
    no_shadow   = true,
})

-- Dialog windows — float + center
hl.window_rule({
    name   = "windowrule-4",
    match  = { title = "^(?i)(Open File)(.*)$" },
    center = true,
    float  = true,
    size   = { "monitor_w*0.6", "monitor_h*0.6" },
})

hl.window_rule({
    name   = "windowrule-5",
    match  = { title = "^(?i)(All files)(.*)$" },
    center = true,
    float  = true,
})

hl.window_rule({
    name   = "windowrule-6",
    match  = { title = "^(?i)(Select a File)(.*)$" },
    center = true,
    float  = true,
    size   = { "monitor_w*0.6", "monitor_h*0.6" },
})

hl.window_rule({
    name   = "windowrule-7",
    match  = { title = "^(?i)(Choose wallpaper)(.*)$" },
    center = true,
    float  = true,
})

hl.window_rule({
    name   = "windowrule-8",
    match  = { title = "^(?i)(Open Folder)(.*)$" },
    center = true,
    float  = true,
    size   = { "monitor_w*0.6", "monitor_h*0.6" },
})

hl.window_rule({
    name   = "windowrule-9",
    match  = { title = "^(?i)(Save As)(.*)$" },
    center = true,
    float  = true,
    size   = { "monitor_w*0.6", "monitor_h*0.6" },
})

hl.window_rule({
    name   = "windowrule-10",
    match  = { title = "^(?i)(Library)(.*)$" },
    center = true,
    float  = true,
})

hl.window_rule({
    name   = "windowrule-11",
    match  = { title = "^(?i)(File Upload)(.*)$" },
    center = true,
    float  = true,
})

hl.window_rule({
    name  = "windowrule-12",
    match = { class = "^(org.pulseaudio.pavucontrol)$" },
    float = true,
})

-- LINE PWA
hl.window_rule({
    name   = "windowrule-LINE",
    match  = { class = "^(msedge-_ophjlpahpchlmihnnnihgmmeilfjmjjc-Default)$" },
    float  = true,
    center = true,
})

-- Blur rules
hl.window_rule({
    name    = "windowrule-13",
    match   = { class = "^()$", title = "^()$" },
    no_blur = true,
})

hl.window_rule({
    name    = "windowrule-14",
    match   = { class = "^(org.gnome.Nautilus)$" },
    no_blur = false,
})

-- ================================ --
-- Layer Rules
-- ================================ --
hl.layer_rule({
    name         = "layerrule-1",
    match        = { namespace = "quickshell:overview" },
    blur         = true,
    ignore_alpha = 0,
    animation    = "fadeLayers",
})

hl.layer_rule({
    name      = "layerrule-waifuland",
    match     = { namespace = "waifuland" },
    animation = "fadeLayers",
})

hl.layer_rule({
    name         = "layerrule-quickvoice",
    match        = { namespace = "quickvoice" },
    blur         = true,
    ignore_alpha = 0,
})

-- vicinae
hl.layer_rule({
    name         = "layerrule-2",
    match        = { namespace = "vicinae" },
    blur         = true,
    ignore_alpha = 0,
    animation    = "slide bottom",
})

-- ================================ --
-- Workspace Rules (disabled, kept for reference)
-- ================================ --
-- hl.workspace_rule({ workspace = "1", monitor = "DP-1", default = true })
-- hl.workspace_rule({ workspace = "2", monitor = "DP-1" })
-- ...
