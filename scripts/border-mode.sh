#!/usr/bin/env bash
set -euo pipefail

# Border Mode Switcher (rofi)
# "With Border"  -> current settings (window rounding 10, mako/swayosd/waybar radius, waybar width 1000)
# "No Border"    -> everything sharp + full-width waybar

DIR="$HOME/.config/scripts/border-mode"
MARKER="$HOME/.config/scripts/.border-mode"
DOTS="$HOME/dots"

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Border Mode" "$1"
    fi
}

apply_waybar_width() {
    local mode="$1"
    python3 -c "
import re, os

path = os.path.expanduser('~/.config/waybar/config.jsonc')
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

if '$mode' == 'noborder':
    content = re.sub(r'\"width\":\s*\d+\s*,?\n', '', content)
else:
    if not re.search(r'\"width\"', content):
        content = re.sub(r'(\"height\":\s*\d+\s*,?)', r'\1\n    \"width\": 1000', content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
" 2>/dev/null || true
}

restart_waybar() {
    if pkill -x waybar 2>/dev/null; then
        while pgrep -x waybar >/dev/null 2>&1; do sleep 0.02; done
        sleep 0.8
    fi
    waybar >/dev/null 2>&1 &
    bash "$HOME/.config/scripts/waybar-hide.sh" apply
}

restart_mako() {
    pkill -x mako 2>/dev/null || true
    sleep 0.2
    mako >/dev/null 2>&1 &
    disown
}

apply_noborder() {
    hyprctl eval 'hl.config({ decoration = { rounding = 0 } })' >/dev/null
    cp "$DIR/mako.conf.noborder" "$HOME/.config/mako/config"
    cp "$DIR/waybar.style.noborder" "$HOME/.config/waybar/style.css"
    cp "$DIR/swayosd.style.noborder" "$HOME/.config/swayosd/style.css"
    cp "$DIR/rofi.config.noborder" "$HOME/.config/rofi/config.rasi"
    apply_waybar_width noborder
    echo "noborder" > "$MARKER"
}

apply_border() {
    hyprctl eval 'hl.config({ decoration = { rounding = 10 } })' >/dev/null
    cp "$DOTS/mako/config" "$HOME/.config/mako/config"
    cp "$DOTS/waybar/style.css" "$HOME/.config/waybar/style.css"
    cp "$DOTS/swayosd/style.css" "$HOME/.config/swayosd/style.css"
    cp "$DOTS/rofi/config.rasi" "$HOME/.config/rofi/config.rasi"
    apply_waybar_width border
    echo "border" > "$MARKER"
}

cmd_menu() {
    local selected
    selected=$(printf "No Border\nWith Border" | rofi -dmenu -i -p "Border Mode:")
    [[ -z "$selected" ]] && exit 0
    case "$selected" in
        "No Border")   apply_noborder ;;
        "With Border") apply_border ;;
    esac
    restart_mako
    systemctl --user restart swayosd-server
    restart_waybar
    notify "$selected"
}

case "${1:-menu}" in
    noborder) apply_noborder; restart_mako; systemctl --user restart swayosd-server; restart_waybar; notify "No Border" ;;
    border)   apply_border;   restart_mako; systemctl --user restart swayosd-server; restart_waybar; notify "With Border" ;;
    menu)     cmd_menu ;;
    *) echo "usage: border-mode.sh [menu|noborder|border]"; exit 1 ;;
esac