-- ================================ --
-- Plugin loading
-- ================================ --
local HOME   = os.getenv("HOME")
local util   = require("hyprland.util")
local SO     = HOME .. "/Documents/Hypr-DarkWindow/out/hypr-darkwindow.so"
local SHADER = "chromakey_vscode"

-- ================================ --
-- Hypr-DarkWindow
-- ================================ --
pcall(hl.plugin.load, SO)

local dw = hl.plugin.darkwindow
if type(dw) ~= "table" or type(dw.load_shader) ~= "function" then return end

do return end -- Disable plugin for now

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
