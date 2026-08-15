---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = true,
        },
    },
})

-- 3-finger swipe to switch workspaces
hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})
