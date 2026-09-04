-- ================================ --
-- Plugin loading (hyprpm-managed)
-- ================================ --
-- Hypr-DarkWindow is installed and built through hyprpm, not from a local
-- checkout. `darkwindow_hyprpm_sync.sh` (autostarted below) keeps the
-- compiled .so in step with the running Hyprland and, when the plugin cannot
-- build for the current Hyprland version, drops a `darkwindow-unavailable`
-- marker so nothing below runs. hyprpm stores the built plugin under
-- /var/cache/hyprpm/<user>/<repo>/<plugin>.so.
local HOME   = os.getenv("HOME")
local util   = require("hyprland.util")
local HYPR   = util.hypr_dir()
-- Match hyprpm's cache dir, which is keyed by the login name. Derive it from
-- $HOME (which Hyprland always sets) rather than trusting a possibly-stale
-- $USER; fall back to $USER only if $HOME is somehow unusable.
local USER   = (HOME and HOME:match("([^/]+)/?$")) or os.getenv("USER") or ""
local SO     = "/var/cache/hyprpm/" .. USER .. "/Hypr-DarkWindow/Hypr-DarkWindow.so"
local SHADER = "chromakey_vscode"
local TOGGLE = HYPR .. "/custom_scripts/toggle_darkwindow_shader.sh"
local SYNC   = HYPR .. "/custom_scripts/darkwindow_hyprpm_sync.sh"
local RUNTIME_DIR = os.getenv("XDG_RUNTIME_DIR")
local INSTANCE    = os.getenv("HYPRLAND_INSTANCE_SIGNATURE")
local RUNTIME     = RUNTIME_DIR and INSTANCE and (RUNTIME_DIR .. "/hypr/" .. INSTANCE)
local STATE_FILE  = RUNTIME and (RUNTIME .. "/darkwindow-shader-enabled")
local UNAVAIL     = RUNTIME and (RUNTIME .. "/darkwindow-unavailable")

local function file_exists(path)
    if not path then return false end

    local file = io.open(path, "r")
    if not file then return false end

    file:close()
    return true
end

-- Public command entry point:
-- hyprctl eval '_G.toggle_darkwindow_shader()'
_G.toggle_darkwindow_shader = function()
    hl.exec_cmd(TOGGLE)
end

-- Rebuild the plugin after a Hyprland update (silent no-op when it is already
-- built for the running commit). Registered here, above the gates: STATE_FILE
-- never exists on a fresh login, so every `return` below is taken and anything
-- placed after them would never run. Skipped in nested test sessions -- the
-- rebuild pops a GUI sudo prompt and writes to the /var/cache/hyprpm tree the
-- real session shares.
if not os.getenv("DOTFILES_NESTED") then
    hl.on("hyprland.start", function()
        hl.exec_cmd(SYNC)
    end)
end

-- ================================ --
-- Hypr-DarkWindow
-- ================================ --
-- Three gates, cheapest first, all fail-safe:
--   1. opt-in: the state file only exists after toggle_darkwindow_shader.sh
--      enables the shader for this compositor instance, so the plugin never
--      touches the default startup path.
--   2. availability: darkwindow_hyprpm_sync.sh sets this marker when the plugin
--      cannot build for the running Hyprland -> keep the feature fully off.
--   3. presence: the hyprpm-built .so must actually exist on disk.
-- The pcall + type() checks below are a final guard against an incompatible .so
-- (e.g. a stale build after a Hyprland update that sync hasn't refreshed yet).
if not file_exists(STATE_FILE) then return end
if file_exists(UNAVAIL) then return end
if not file_exists(SO) then return end

pcall(hl.plugin.load, SO)

local dw = hl.plugin.darkwindow
if type(dw) ~= "table" or type(dw.load_shader) ~= "function" then return end

dw.load_shader(SHADER, {
    path                    = HYPR .. "/shaders/multi_chromakey.frag",
    introduces_transparency = true,
    args                    = "count=3"
        .. " bkg[0]=" .. util.hex_rgb("#121314") .. " similarity[0]=0.03 amount[0]=1 targetOpacity[0]=0.70"
        .. " bkg[1]=" .. util.hex_rgb("#191A1B") .. " similarity[1]=0.03 amount[1]=1 targetOpacity[1]=0.70"
        .. " bkg[2]=" .. util.hex_rgb("#242526") .. " similarity[2]=0.03 amount[2]=1 targetOpacity[2]=0.70",
})

hl.window_rule({
    name                 = "windowrule-16",
    match                = { class = "^(code)$" },
    ["darkwindow:shade"] = SHADER,
})
