-- ================================ --
-- Hyprland Var Configuration
-- ================================ --
local hypr = require("hyprland.util").hypr_dir()

return {
    terminal         = "foot",
    fileManager      = "nautilus",
    menu             = "rofi -show drun",
    menu_kill        = "pkill rofi",
    audio_menu       = hypr .. "/custom_scripts/change_audio.sh",
    gamemode_toggle  = hypr .. "/custom_scripts/gamemode.sh",
}
