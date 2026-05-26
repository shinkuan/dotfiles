-- ================================ --
-- Small config helpers
-- ================================ --
local M = {}

--- Convert a hex color into Hypr-DarkWindow's "[r g b]" float syntax (0–1).
--- Each channel is divided by 255 (so #ffffff -> 1.0), matching how the GPU
--- normalises 8-bit window pixels — the correct basis for chromakey matching.
--- Accepts "#rrggbb" / "rrggbb" and shorthand "#rgb" / "rgb".
---
--- Usage: args = "bkg=" .. util.hex_rgb("#151312") .. " similarity=0.01 ..."
---
---@param hex string
---@return string bracket  e.g. "[0.08235294 0.07450981 0.07058824]"
---@return number r 0–1
---@return number g 0–1
---@return number b 0–1
function M.hex_rgb(hex)
    hex = tostring(hex):gsub("^#", ""):gsub("%s", "")
    if #hex == 3 then                       -- expand #rgb -> #rrggbb
        hex = hex:gsub("(%x)", "%1%1")
    end
    assert(#hex == 6 and hex:match("^%x+$"),
        "hex_rgb: expected 3 or 6 hex digits, got '" .. tostring(hex) .. "'")

    local r = tonumber(hex:sub(1, 2), 16) / 255
    local g = tonumber(hex:sub(3, 4), 16) / 255
    local b = tonumber(hex:sub(5, 6), 16) / 255

    return string.format("[%.8g %.8g %.8g]", r, g, b), r, g, b
end

return M
