-- ================================ --
-- Hyprland entry point (Lua)
-- ================================ --
-- See https://wiki.hypr.land/Configuring/Start/
--
-- Each `require` loads a separate file. Hyprland sandboxes each one so
-- that an error in one file does not abort the rest of the config.

require("hyprland.env")
require("hyprland.cursor")
require("hyprland.monitors")
require("hyprland.general")
require("hyprland.rules")
require("hyprland.keybinds")
require("hyprland.execs")
require("hyprland.rpm")
