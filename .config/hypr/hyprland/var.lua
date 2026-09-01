-- ================================ --
-- Hyprland Var Configuration
-- ================================ --
local hypr = require("hyprland.util").hypr_dir()

return {
    terminal         = "foot",
    fileManager      = "nautilus",
    menu             = "qs -c desktop ipc call launcher toggle",
    gamemode_toggle  = hypr .. "/custom_scripts/gamemode.sh",
}
