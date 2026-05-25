-- ================================ --
-- KGrid — 2D workspace engine (replaces hyprkool)
-- ================================ --
-- Maps a per-activity W×H grid onto deterministic *numeric* workspace ids.
--
-- Why numeric ids: Hyprland decides a workspace switch's slide *direction*
-- (forward vs reverse) purely from the workspace id delta — there is no
-- direction-hint API. hyprkool used named workspaces, whose ids are assigned
-- in creation order (negative, counting down) and therefore get reshuffled on
-- `hyprctl reload`, which flipped the slide direction. Here every cell's id is
-- a pure function of its grid position, so the id delta — and thus the slide
-- direction — is identical before and after a reload.
--
-- id(ai,x,y) = 1 + ai*W*H + (y-1)*W + (x-1)
--   horizontal neighbour: ±1   → "slide"
--   vertical   neighbour: ±W   → "slidevert"
--
-- Cells are *not* pre-created or persistent. A `default_name` workspace rule
-- per id (declared at the bottom) makes a cell adopt its "activity:(x y)" name
-- the moment it is focused; empty unfocused cells auto-destroy, keeping the bar
-- clean. The ids stay deterministic regardless, so direction is reload-stable.

local M = {}

M.activities = { "default", "Z", "X", "C", "A", "S", "D", "Q", "W", "E" }
M.W, M.H = 5, 5

-- Carry remembered-cell state across reloads via the shared Lua state.
M.last = (_G.KGrid and _G.KGrid.last) or {}  -- M.last[activity] = { x = , y = }

-- activity name -> 0-based index
local index = {}
for i, a in ipairs(M.activities) do index[a] = i - 1 end

local function id_of(ai, x, y)
    return 1 + ai * M.W * M.H + (y - 1) * M.W + (x - 1)
end

local function name_of(ai, x, y)
    return string.format("%s:(%d %d)", M.activities[ai + 1], x, y)
end

-- Parse the focused workspace into (activity, x, y); nil if not a grid cell.
local function current()
    local ws = hl.get_active_workspace()
    if not ws or not ws.name then return nil end
    local a, x, y = ws.name:match("^(.-):%((%d+) (%d+)%)$")
    if not a or not index[a] then return nil end
    return a, tonumber(x), tonumber(y)
end

-- Pick the workspace-switch animation *style* right before a switch. Direction
-- is Hyprland's call (from the id delta); we only choose the axis style.
-- speed/curve mirror the `workspaces` leaf in general.lua.
local function set_anim(style)
    hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "standard", style = style })
end

-- Focus (or carry the active window to) a grid cell. Creates it on demand;
-- the default_name rule gives it its "activity:(x y)" name.
local function go_to(ai, x, y, carry)
    local id = id_of(ai, x, y)
    if carry then
        hl.dispatch(hl.dsp.window.move({ workspace = id, follow = true }))
    else
        hl.dispatch(hl.dsp.focus({ workspace = id }))
    end
    M.last[M.activities[ai + 1]] = { x = x, y = y }
end

-- Move within the current activity by (dx, dy). Clamps at edges (no wrap),
-- matching the previous `hyprkool move-*` default (cycle = false).
function M.go(dx, dy, carry)
    local a, x, y = current()
    if not a then return end
    local nx, ny = x + dx, y + dy
    if nx < 1 or nx > M.W or ny < 1 or ny > M.H then return end
    set_anim(dx ~= 0 and "slide" or "slidevert")
    go_to(index[a], nx, ny, carry)
end

-- Switch to an activity, landing on its remembered cell (default 1,1).
-- Cross-activity jumps have no meaningful slide direction -> fade.
function M.switch_activity(name, carry)
    if not index[name] then return end
    local last = M.last[name] or { x = 1, y = 1 }
    set_anim("fade")
    go_to(index[name], last.x, last.y, carry)
end

-- Switch to an explicit "activity:(x y)" cell. Used by the overview.
-- slide/slidevert when staying in the same row/col of the same activity,
-- otherwise fade (different activity, diagonal, or wrap).
function M.switch_name(target, carry)
    local a, x, y = target:match("^(.-):%((%d+) (%d+)%)$")
    if not a or not index[a] then return end
    x, y = tonumber(x), tonumber(y)
    local ca, cx, cy = current()
    local style = "fade"
    if ca == a then
        if cy == y and cx ~= x then style = "slide"
        elseif cx == x and cy ~= y then style = "slidevert" end
    end
    set_anim(style)
    go_to(index[a], x, y, carry)
end

-- Declare a default_name rule for every cell so it self-names on creation.
for ai = 0, #M.activities - 1 do
    for y = 1, M.H do
        for x = 1, M.W do
            hl.workspace_rule({ workspace = tostring(id_of(ai, x, y)), default_name = name_of(ai, x, y) })
        end
    end
end

_G.KGrid = M
return M
