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
    local mon_h
    mon_h=$(hyprctl monitors -j 2>/dev/null | python3 -c "import json,sys
try:
    print(json.load(sys.stdin)[0]['height'])
except Exception:
    print(1080)")
    python3 -c "
import re, os

path = os.path.expanduser('~/.config/waybar/config.jsonc')
pos_path = os.path.expanduser('~/.config/waybar/.current_position')
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

pos = 'top'
if os.path.exists(pos_path):
    with open(pos_path, 'r') as pf:
        pos = pf.read().strip() or 'top'

if pos in ('left', 'right'):
    # Vertical bar: 37px width mandatory; height mirrors the horizontal bar
    # (1000 centered in border mode, full monitor height in no-border mode).
    if '\"width\"' not in content:
        content = re.sub(r'(\"height\":\s*\d+)\s*,?', r'\1,\n    \"width\": 37,', content)
    else:
        content = re.sub(r'\"width\":\s*\d+', '\"width\": 37', content)
    bar_h = $mon_h if '$mode' == 'noborder' else 1000
    content = re.sub(r'\"height\":\s*\d+', f'\"height\": {bar_h}', content)
elif '$mode' == 'noborder':
    # Horizontal full-width bar: no width key at all.
    content = re.sub(r'\"width\":\s*\d+\s*,?\n', '', content)
else:
    # Horizontal centered bar (border mode).
    if not re.search(r'\"width\"', content):
        content = re.sub(r'(\"height\":\s*\d+)\s*,?', r'\1,\n    \"width\": 1000,', content)
    else:
        content = re.sub(r'\"width\":\s*\d+', '\"width\": 1000', content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
" 2>/dev/null || true
}

restart_waybar() {
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
    cp "$DIR/mako.conf.border" "$HOME/.config/mako/config"
    cp "$DIR/waybar.style.border" "$HOME/.config/waybar/style.css"
    cp "$DIR/swayosd.style.border" "$HOME/.config/swayosd/style.css"
    cp "$DIR/rofi.config.border" "$HOME/.config/rofi/config.rasi"
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