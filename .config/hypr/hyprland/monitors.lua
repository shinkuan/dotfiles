-- ================================ --
-- Monitors
-- ================================ --
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

-- hl.monitor({ output = "DP-1",     mode = "2560x1440@170.07Hz", position = "0x0",        scale = 1 })
-- hl.monitor({ output = "DP-2",     mode = "2560x1440@179.88Hz", position = "-2560x0",    scale = 1 })
-- hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@120Hz",    position = "2560x-1440", scale = 1 })

-- Fallback for any unspecified output:
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- Examples kept for reference:
-- hl.monitor({ output = "DP-2", mode = "2560x1440@179.88Hz", position = "-1440x-750", scale = 1, transform = 3 })
-- hl.monitor({ output = "HDMI-A-1", disabled = true })
