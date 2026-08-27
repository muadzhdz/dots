-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Pure Monochrome Configuration (Dark Only)

hl.config({
    general = {
        gaps_in  = 10,
        gaps_out = 15,

        border_size = 1,

        col = {
            active_border   = { colors = {"rgba(ffffffff)"} },
            inactive_border = "rgba(333333ff)",
        },

        resize_on_border = true,
        allow_tearing = false,
    },

    decoration = {
        rounding       = 0,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        dim_special = 0.45,

        shadow = {
            enabled      = false,
        },

        blur = {
            enabled   = true,
            size      = 10,
            passes    = 3,
            vibrancy  = 0.1696,
            special   = true, -- Backdrop blur for special workspace (scratchpad)
        },
    },

    animations = {
        enabled = true,
    },
})

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

hl.animation({ leaf = "global",           enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",           enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",          enabled = true,  speed = 3.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",        enabled = true,  speed = 3,  bezier = "quick", style = "popin 80%" })
hl.animation({ leaf = "windowsOut",       enabled = true,  speed = 1.5, bezier = "linear",       style = "popin 80%" })
hl.animation({ leaf = "fadeIn",           enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",          enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",             enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",           enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",         enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "layersOut",        enabled = true,  speed = 1.5,  bezier = "linear",       style = "slide" })
hl.animation({ leaf = "fadeLayersIn",     enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut",    enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",       enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "slidevert bottom" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "slidevert top" })
