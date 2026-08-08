-- ================================ --
-- Plugin loading
-- ================================ --
local HOME   = os.getenv("HOME")
local util   = require("hyprland.util")
local SO     = HOME .. "/Documents/Hypr-DarkWindow/out/hypr-darkwindow.so"
local SHADER = "chromakey_vscode"
local TOGGLE = HOME .. "/.config/hypr/custom_scripts/toggle_darkwindow_shader.sh"
local RUNTIME_DIR = os.getenv("XDG_RUNTIME_DIR")
local INSTANCE    = os.getenv("HYPRLAND_INSTANCE_SIGNATURE")
local STATE_FILE  = RUNTIME_DIR and INSTANCE
    and RUNTIME_DIR .. "/hypr/" .. INSTANCE .. "/darkwindow-shader-enabled"

local function file_exists(path)
    if not path then return false end

    local file = io.open(path, "r")
    if not file then return false end

    file:close()
    return true
end

-- Public command entry point:
-- hyprctl eval '_G.toggle_darkwindow_shader()'
_G.toggle_darkwindow_shader = function()
    hl.exec_cmd(TOGGLE)
end

-- ================================ --
-- Hypr-DarkWindow
-- ================================ --
-- Keep the plugin and shader out of the default startup path. The state file
-- only exists after toggle_darkwindow_shader.sh enables it for this compositor
-- instance, so an incompatible plugin cannot block the next Hyprland session.
if not file_exists(STATE_FILE) then return end

pcall(hl.plugin.load, SO)

local dw = hl.plugin.darkwindow
if type(dw) ~= "table" or type(dw.load_shader) ~= "function" then return end

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
