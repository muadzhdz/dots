---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
local terminal    = "kitty"
local fileManager = "dolphin"
local menu        = "hyprlauncher"
local scriptsDir     = os.getenv("HOME") .. "/.config/scripts"
local launcher    = scriptsDir .. "/launcher.sh"
local powerMenu   = scriptsDir .. "/powermenu.sh"
local emojiPicker = scriptsDir .. "/emoji.sh"
local screenshot  = scriptsDir .. "/screenshot.sh"
local ocr         = scriptsDir .. "/ocr.sh"
local clipRofi    = scriptsDir .. "/clipboard_rofi.sh"
local monitorScaling = scriptsDir .. "/monitor-scaling.sh"
local wallpaper      = scriptsDir .. "/wallpaper.sh"
local wallpaperPicker = scriptsDir .. "/wallpaper-picker.sh"
local lock           = "hyprlock"

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(lock), { locked = true })
hl.bind(mainMod .. " + SPACE",       hl.dsp.exec_cmd(launcher))
hl.bind(mainMod .. " + ALT + SPACE", hl.dsp.exec_cmd("pkill rofi; rofi -show power-menu -modi power-menu:" .. powerMenu))
hl.bind(mainMod .. " + SHIFT + SPACE", hl.dsp.exec_cmd("killall -SIGUSR1 waybar"))
hl.bind(mainMod .. " + slash",     hl.dsp.exec_cmd(monitorScaling))
hl.bind(mainMod .. " + ALT + slash", hl.dsp.exec_cmd(monitorScaling .. " --reverse"))
hl.bind(mainMod .. " + ALT + E",     hl.dsp.exec_cmd(emojiPicker))
hl.bind(mainMod .. " + W",           hl.dsp.exec_cmd(wallpaper .. " random"))
hl.bind(mainMod .. " + SHIFT + W",   hl.dsp.exec_cmd("pkill rofi; rofi -modi \"wallpaper:" .. wallpaperPicker .. "\" -show wallpaper"))

hl.bind(mainMod .. " + V",
    hl.dsp.exec_cmd("pkill rofi; rofi -modi \"clipboard:" .. clipRofi .. "\" -show clipboard"),
    { description = "Clipboard History" })

hl.bind("Print",                 hl.dsp.exec_cmd(screenshot))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(screenshot))
hl.bind(mainMod .. " + Print",     hl.dsp.exec_cmd(ocr))
local closeWindowBind = hl.bind(mainMod .. " + Q", hl.dsp.window.close())
-- closeWindowBind:set_enabled(false)
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))    -- dwindle only

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Alt+Tab: cycle windows
hl.bind("ALT + Tab",         hl.dsp.window.cycle_next(),                   { description = "Focus on next window" })
hl.bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({ prev = true }),    { description = "Focus on previous window" })
hl.bind("ALT + Tab",         hl.dsp.window.bring_to_top(),                 { description = "Reveal active window on top" })
hl.bind("ALT + SHIFT + Tab", hl.dsp.window.bring_to_top(),                 { description = "Reveal active window on top" })

-- Ctrl+Alt+Tab: cycle monitors
hl.bind("CTRL + ALT + Tab",         hl.dsp.focus({ monitor = "+1" }), { description = "Focus on next monitor" })
hl.bind("CTRL + ALT + SHIFT + Tab", hl.dsp.focus({ monitor = "-1" }), { description = "Focus on previous monitor" })

-- Swap windows with mainMod + SHIFT + arrow keys
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.swap({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.swap({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.swap({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.swap({ direction = "d" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"),       { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"),       { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("swayosd-client --brightness raise"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("swayosd-client --brightness lower"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

