-- ================================ --
-- Hyprland entry point (Lua)
-- ================================ --
-- See https://wiki.hypr.land/Configuring/Start/
--
-- Each `require` loads a separate file. Hyprland sandboxes each one so
-- that an error in one file does not abort the rest of the config.

-- Copy src to dst, but only if dst doesn't already exist
local function maybe_copy(src, dst)
    local out = io.open(dst)
    if out then
        out:close()
        return
    end

    local input = io.open(src, "r")
    if not input then return end

    out = io.open(dst, "w")
    if out then
        out:write(input:read("*a"))
        out:close()
    end
    input:close()
end

-- Maybe set current colours to defaults (current.lua is regenerated on
-- scheme changes and is gitignored)
local hypr = require("hyprland.util").hypr_dir()
maybe_copy(hypr .. "/scheme/default.lua", hypr .. "/scheme/current.lua")

require("hyprland.env")
require("hyprland.cursor")
require("hyprland.monitors")
require("hyprland.general")
require("hyprland.rules")
require("hyprland.kgrid")    -- 2D workspace engine (defines _G.KGrid); must load before keybinds
require("hyprland.keybinds")
require("hyprland.execs")
require("hyprland.rpm")
require("hyprland.local")  -- per-machine overrides (gitignored; cp local.lua.example -> local.lua)
