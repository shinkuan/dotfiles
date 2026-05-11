-- ================================ --
-- Hyprland Var Configuration
-- ================================ --
local home = os.getenv("HOME")

return {
    terminal         = "foot",
    fileManager      = "nautilus",
    menu             = "rofi -show drun",
    menu_kill        = "pkill rofi",
    copy_menu        = "cliphist list | rofi -dmenu | cliphist decode | wl-copy",
    copy_menu_delete = "cliphist list | rofi -dmenu | cliphist delete",
    emoji_menu       = "cat ~/.local/share/caelestia/scripts/data/emojis.txt | rofi -dmenu | cut -d ' ' -f 1 | tr -d '\\n' | wl-copy",
    audio_menu       = home .. "/.config/hypr/custom_scripts/change_audio.sh",
    gamemode_toggle  = home .. "/.config/hypr/custom_scripts/gamemode.sh",
}
