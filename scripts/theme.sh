#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Pure Monochrome Theme Controller (Dark Only) - Strictly Black & White
# ─────────────────────────────────────────────────────────────────────────────

THEMES_DIR="$HOME/.config/themes"
MARKER="$HOME/.config/scripts/.theme"
LEGACY_MARKER="$HOME/.config/scripts/.theme-mode"

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -i preferences-desktop-theme "Theme" "$1"
    fi
}

get_current_theme() {
    if [[ -f "$MARKER" ]]; then
        cat "$MARKER"
    else
        echo "dark"
    fi
}

reload_daemons() {
    if pgrep -x mako >/dev/null 2>&1; then
        pkill -x mako 2>/dev/null || true
        sleep 0.1
        mako >/dev/null 2>&1 &
        disown
    fi

    systemctl --user restart swayosd-server.service 2>/dev/null || true

    if [[ -f "$HOME/.config/scripts/waybar-hide.sh" ]]; then
        bash "$HOME/.config/scripts/waybar-hide.sh" apply 2>/dev/null || true
    fi

    pkill -USR1 kitty 2>/dev/null || true
    gdbus call --session --dest com.mitchellh.ghostty --object-path /com/mitchellh/ghostty --method org.gtk.Actions.Activate reload-config '[]' '{}' >/dev/null 2>&1 || true
    pkill -USR1 ghostty 2>/dev/null || true
    pkill -USR2 btop 2>/dev/null || true

    if pgrep -x nautilus >/dev/null 2>&1 && [[ -f "$HOME/.config/scripts/reload-nautilus.sh" ]]; then
        bash "$HOME/.config/scripts/reload-nautilus.sh" 2>/dev/null || true
    fi

    hyprctl reload >/dev/null 2>&1 || true
}

apply_dark() {
    echo "dark" > "$MARKER"
    echo "dark" > "$LEGACY_MARKER"

    hyprctl eval 'hl.config({ decoration = { active_opacity = 1.0, inactive_opacity = 1.0, dim_special = 0.45, shadow = { enabled = false }, blur = { enabled = true, special = true, size = 10, passes = 3 } }, general = { col = { active_border = { colors = {"rgba(ffffffff)"} }, inactive_border = "rgba(333333ff)" } } })' >/dev/null 2>&1 || true

    mkdir -p "$HOME/.config/mako" "$HOME/.config/rofi" "$HOME/.config/swayosd" "$HOME/.config/waybar" "$HOME/.config/kitty" "$HOME/.config/ghostty/themes" "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0" "$HOME/.config/btop/themes"

    cp "$THEMES_DIR/dark/mako.conf" "$HOME/.config/mako/config"
    cp "$THEMES_DIR/dark/rofi-theme.rasi" "$HOME/.config/rofi/theme.rasi"
    cp "$THEMES_DIR/dark/swayosd.css" "$HOME/.config/swayosd/style.css"
    cp "$THEMES_DIR/dark/waybar-colors.css" "$HOME/.config/waybar/colors.css"
    cp "$THEMES_DIR/dark/kitty.conf" "$HOME/.config/kitty/theme.conf"
    cp "$THEMES_DIR/dark/ghostty.conf" "$HOME/.config/ghostty/themes/current"
    cp "$THEMES_DIR/dark/gtk.css" "$HOME/.config/gtk-3.0/gtk.css"
    cp "$THEMES_DIR/dark/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"
    cp "$THEMES_DIR/dark/btop.theme" "$HOME/.config/btop/themes/current.theme"
    cp "$THEMES_DIR/dark/shell-env.sh" "$HOME/.config/themes/active-env.sh"

    gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark 2>/dev/null || true
    dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'" 2>/dev/null || true
    python3 "$HOME/.config/scripts/sync-browser-theme.py" dark 2>/dev/null || true
    python3 "$HOME/.config/scripts/sync-apps-theme.py" dark 2>/dev/null || true

    local black_wp="$HOME/Pictures/Wallpapers/black.png"
    if [[ -f "$black_wp" ]] && pgrep -x awww-daemon >/dev/null 2>&1; then
        awww img --transition-type fade --transition-duration 1.0 --transition-fps 60 "$black_wp" 2>/dev/null || true
        echo "$black_wp" > "$HOME/.config/scripts/.current_wallpaper"
    fi

    bash "$HOME/.config/scripts/sddm-sync.sh" 2>/dev/null || true

    reload_daemons
    notify "Dark Mode Activated (Monochrome Black & White)"
}

chmod +x /home/muadzhdz/.config/scripts/theme.sh 2>/dev/null || true

case "${1:-dark}" in
    dark)   apply_dark ;;
    get)    get_current_theme ;;
    *)
        echo "Usage: theme.sh {dark|get}"
        exit 1
        ;;
esac
