--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

hl.window_rule({
    name  = "float-tui-apps",
    match = {
        title = "^(btop|wiremix|bluetui|impala)$",
    },
    float = true,
    size  = {875, 600},
})

-- Semua window non-fullscreen tidak boleh nahan idle (idle inhibitor),
-- biar hypridle lock/screen-off selalu jalan tepat waktu apa pun aplikasinya.
-- Window fullscreen (mis. video fullscreen) tetap bisa nahan idle.
-- https://issues.chromium.org/issues/386887875
hl.window_rule({
    name  = "ignore-idle-inhibit",
    match = {
        class      = ".*",
        fullscreen = false,
    },
    idle_inhibit = "none",
})

hl.layer_rule({
    name  = "waybar-blur",
    match = { namespace = "waybar" },
    blur = true,
    ignore_alpha = 0.3,
})

hl.layer_rule({
    name  = "rofi-blur",
    match = { namespace = "rofi" },
    blur = true,
    ignore_alpha = 0.3,
})

hl.layer_rule({
    name  = "mako-blur",
    match = { namespace = "notifications" },
    blur = true,
    ignore_alpha = 0.3,
})

hl.layer_rule({
    name  = "swayosd-blur",
    match = { namespace = "swayosd" },
    blur = true,
    ignore_alpha = 0.3,
})

-- Polkit KDE agent — float + sedikit transparan supaya blur global kelihatan
hl.window_rule({
    name  = "polkit-kde-float",
    match = { class = "org.kde.polkit-kde-authentication-agent-1" },
    float   = true,
    opacity = "0.92 override 0.92 override",
})

-- XDG portal / screenshot selector
hl.window_rule({
    name  = "xdg-portal-float",
    match = { class = "xdg-desktop-portal-gtk" },
    float   = true,
    opacity = "0.92 override 0.92 override",
})

-- Semua floating window dapat opacity sedikit transparan (blur global sudah aktif di decorations)
hl.window_rule({
    name    = "float-opacity",
    match   = { float = true },
    opacity = "0.92 override 0.92 override",
})

-- Rofi layer (wayland backend: di-spawn tanpa DISPLAY di launcher.py) -- arah ikut posisi waybar
hl.layer_rule({
    name      = "rofi-anim",
    match     = { namespace = "rofi" },
    animation = "slide",
})
