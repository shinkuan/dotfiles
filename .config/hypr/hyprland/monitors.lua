-- ================================ --
-- Monitors
-- ================================ --
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
--
-- Machine-specific monitor rules live in local.lua (gitignored).
-- Specific rules there take precedence over the generic fallback below.

-- Fallback for any unspecified output:
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- Examples kept for reference:
-- hl.monitor({ output = "DP-1",     mode = "2560x1440@170.07Hz", position = "0x0",        scale = 1 })
-- hl.monitor({ output = "DP-2",     mode = "2560x1440@179.88Hz", position = "-1440x-750", scale = 1, transform = 3 })
-- hl.monitor({ output = "HDMI-A-1", mode = "3840x2160@239.99Hz", position = "-2560x0",    scale = 1.5, bitdepth = 10 })
-- hl.monitor({ output = "HDMI-A-1", disabled = true })
