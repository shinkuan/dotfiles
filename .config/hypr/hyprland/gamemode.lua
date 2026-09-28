-- ================================ --
-- Game mode
-- ================================ --
-- Toggled by the desktop shell (Quick settings, `qs -c desktop ipc call
-- gameMode toggle`), which creates or removes the flag file and then runs
-- `hyprctl reload config-only`. The flag lives in the per-instance runtime
-- dir, so every new session starts with game mode off. Loaded last so it
-- also wins over local.lua.

local RUNTIME_DIR = os.getenv("XDG_RUNTIME_DIR")
local INSTANCE    = os.getenv("HYPRLAND_INSTANCE_SIGNATURE")
if not (RUNTIME_DIR and INSTANCE) then return end

local flag = io.open(RUNTIME_DIR .. "/hypr/" .. INSTANCE .. "/gamemode")
if not flag then return end
flag:close()

hl.config({
    general = {
        gaps_in     = 0,
        gaps_out    = 0,
        border_size = 1,
    },
    decoration = {
        rounding = 0,
        blur     = { enabled = false },
        shadow   = { enabled = false },
    },
    animations = { enabled = false },
})
