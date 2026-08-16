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

-- 3-finger swipe to switch workspaces (horizontal; waybar-position.sh
-- switches it to vertical when the waybar sits on the left/right)
hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})
