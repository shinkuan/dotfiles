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

-- id is the internal name used in workspace names; label is what the shell
-- shows (text or a Nerd Font glyph).
M.defs = {
    { id = "main", label = "main" },
    { id = "Z", label = "Z" },
    { id = "X", label = "X" },
    { id = "C", label = "C" },
    { id = "A", label = "A" },
    { id = "S", label = "S" },
    { id = "D", label = "D" },
    { id = "Q", label = "Q" },
    { id = "W", label = "W" },
    { id = "E", label = "E" },
}
M.activities = {}
for i, d in ipairs(M.defs) do M.activities[i] = d.id end
M.W, M.H = 5, 5

-- Single source of truth for the shell: $XDG_RUNTIME_DIR/hypr/<sig>/kgrid.json
local function export_json()
    local runtime, sig = os.getenv("XDG_RUNTIME_DIR"), os.getenv("HYPRLAND_INSTANCE_SIGNATURE")
    if not runtime or not sig or not io then return end
    local f = io.open(runtime .. "/hypr/" .. sig .. "/kgrid.json", "w")
    if not f then return end
    local parts = {}
    for i, d in ipairs(M.defs) do
        parts[i] = string.format('{"id":%q,"label":%q}', d.id, d.label)
    end
    f:write(string.format('{"W":%d,"H":%d,"activities":[%s]}\n', M.W, M.H, table.concat(parts, ",")))
    f:close()
end
export_json()

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

-- Focus (or carry the active window to) a grid cell, always landing on the
-- monitor the user is operating from. Creates the cell on demand; the
-- default_name rule gives it its "activity:(x y)" name.
--
-- The problem this solves: Hyprland binds every workspace to the monitor it was
-- created on, and `focusworkspace` *follows* the target to its owning monitor.
-- So focusing a cell owned by the other monitor yanks focus across screens —
-- exactly what we don't want. We branch on where the target currently lives:
--   * on this monitor already, or not created yet -> plain focus. Identical to
--     the old single-dispatch path, so the grid's slide animation is preserved.
--   * VISIBLE on the other monitor -> swap the two monitors' active workspaces,
--     so the target slides here and our current workspace goes there. Focus is
--     re-anchored to this monitor afterwards (the swap can drag input focus away
--     with the window that moved out).
--   * hidden on the other monitor -> pull the workspace onto this monitor, then
--     focus it here.
local function go_to(ai, x, y, carry)
    local id  = id_of(ai, x, y)
    local cur = hl.get_active_monitor()
    local ws  = cur and hl.get_workspace(id)

    if not cur or not ws or (ws.monitor and ws.monitor.id == cur.id) then
        -- Same monitor (or brand-new cell): keep the original behaviour.
        if carry then
            hl.dispatch(hl.dsp.window.move({ workspace = id, follow = true }))
        else
            hl.dispatch(hl.dsp.focus({ workspace = id }))
        end
    else
        -- Target lives on the OTHER monitor. Carry the window over silently
        -- first; the branches below bring the *view* to the current monitor.
        if carry then
            hl.dispatch(hl.dsp.window.move({ workspace = id, follow = false }))
        end
        local om = ws.monitor
        if om and om.active_workspace and om.active_workspace.id == id then
            hl.dispatch(hl.dsp.workspace.swap_monitors({ monitor1 = cur.name, monitor2 = om.name }))
            hl.dispatch(hl.dsp.focus({ monitor = cur.name }))
        else
            hl.dispatch(hl.dsp.workspace.move({ workspace = id, monitor = cur.name }))
            hl.dispatch(hl.dsp.focus({ workspace = id }))
        end
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

-- Move a window (by address) into the cell named "activity:(x y)", resolving to
-- the deterministic numeric id. The overview must NOT move by `name:`: an empty
-- target cell has no workspace yet, so Hyprland would mint a fresh workspace
-- with an arbitrary id that steals the "activity:(x y)" name. KGrid would then
-- focus the *numeric-id* cell (still empty) on navigation, leaving the moved
-- window unreachable even though the overview keeps listing it by name.
-- Resolving to id_of pins the window to the exact workspace KGrid later focuses.
function M.move_window_to_name(target, address, follow)
    local a, x, y = target:match("^(.-):%((%d+) (%d+)%)$")
    if not a or not index[a] then return end
    x, y = tonumber(x), tonumber(y)
    local id = id_of(index[a], x, y)
    hl.dispatch(hl.dsp.window.move({ workspace = id, window = "address:" .. address, follow = follow or false }))
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
