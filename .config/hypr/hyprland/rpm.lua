-- ================================ --
-- Plugin loading
-- ================================ --
local HOME = os.getenv("HOME")
local util = require("hyprland.util")

-- ================================ --
-- Hypr-DarkWindow
-- ================================ --
-- hl.plugin.load() is a DECLARATIVE call: on every config evaluation Hyprland
-- syncs its loaded plugins to whatever the config declares this pass. So it
-- MUST be called unconditionally on every eval — guarding it (e.g. only when
-- hl.plugin.darkwindow == nil) makes alternate re-evals stop declaring it,
-- Hyprland unloads it, that triggers another re-eval, and you get an infinite
-- load/unload loop that hangs startup. Do not add a nil-guard around it.
--
-- DANGER: never `hyprctl plugin unload` a darkwindow build that failed to load
-- — dlclose on a half-initialised plugin SEGV's the whole compositor.
local SO = HOME .. "/Documents/Hypr-DarkWindow/out/hypr-darkwindow.so"
pcall(hl.plugin.load, SO)

local dw = hl.plugin.darkwindow
if type(dw) == "table" and type(dw.load_shader) == "function" then
    local SHADER = "chromakey_vscode_v2"

    dw.load_shader(SHADER, {
        path                    = HOME .. "/.config/hypr/shaders/multi_chromakey.frag",
        introduces_transparency = true,
        args                    = "count=3"
            .. " bkg[0]=" .. util.hex_rgb("#121314") .. " similarity[0]=0.03 amount[0]=1 targetOpacity[0]=0.70"
            .. " bkg[1]=" .. util.hex_rgb("#191A1B") .. " similarity[1]=0.03 amount[1]=1 targetOpacity[1]=0.70"
            .. " bkg[2]=" .. util.hex_rgb("#242526") .. " similarity[2]=0.03 amount[2]=1 targetOpacity[2]=0.70",
    })

    hl.window_rule({
        name                 = "windowrule-16",
        match                = { class = "^(code)$" },
        ["darkwindow:shade"] = SHADER,
    })
end
