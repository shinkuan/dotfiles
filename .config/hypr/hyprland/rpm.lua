-- ================================ --
-- hyprpm / plugin loading
-- ================================ --
hl.on("hyprland.start", function()
    hl.exec_cmd("hyprpm reload -n")
    hl.exec_cmd("hyprctl plugin load " .. os.getenv("HOME") .. "/Documents/Hypr-DarkWindow/out/hypr-darkwindow.so")
end)
