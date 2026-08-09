------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

-- Apply last chosen resolution/scale (saved by scripts/display.sh) if present
local cache_path = os.getenv("HOME") .. "/.config/hypr/.monitor-cache"
local cache_file = io.open(cache_path, "r")
if cache_file then
    local line = cache_file:read("*l")
    cache_file:close()
    local output, mode, scale = line:match("^(%S+) (%S+) (%S+)$")
    if output and mode and scale then
        hl.monitor({
            output   = output,
            mode     = mode,
            position = "auto",
            scale    = scale,
        })
    end
end

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "1",
})

-- Workspaces 1-5 on main monitor
hl.workspace_rule({ workspace = "1", monitor = "", persistent = true })
hl.workspace_rule({ workspace = "2", monitor = "", persistent = true })
hl.workspace_rule({ workspace = "3", monitor = "", persistent = true })
hl.workspace_rule({ workspace = "4", monitor = "", persistent = true })
hl.workspace_rule({ workspace = "5", monitor = "", persistent = true })
