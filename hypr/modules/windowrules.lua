--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
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

hl.window_rule({
    name  = "ignore-idle-inhibit",
    match = {
        class      = ".*",
        fullscreen = false,
    },
    idle_inhibit = "none",
})

hl.window_rule({
    name  = "polkit-kde-float",
    match = { class = "org.kde.polkit-kde-authentication-agent-1" },
    float = true,
})

hl.window_rule({
    name  = "xdg-portal-float",
    match = { class = "xdg-desktop-portal-gtk" },
    float = true,
})

hl.layer_rule({
    name      = "rofi-anim",
    match     = { namespace = "rofi" },
    animation = "slide",
})
