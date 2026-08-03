-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function() 
   hl.exec_cmd("hyprctl setcursor Yaru 21")
   hl.exec_cmd("waybar")
   hl.exec_cmd("mako")
   hl.exec_cmd("awww-daemon")
   hl.exec_cmd("systemctl --user --quiet enable --now cliphist")
   hl.exec_cmd("bash -c 'sleep 0.5 && $HOME/.config/scripts/wallpaper.sh init'")
end)