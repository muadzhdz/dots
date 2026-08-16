#!/usr/bin/env bash

# Waybar Position & Hyprland Workspace Animation Switcher
# Top/Bottom -> Workspaces animation = "slide" (horizontal), swipe horizontal
# Left/Right -> Workspaces animation = "slidevert" (vertical), swipe vertical
#
# The special workspace (scratchpad) slides in from the side OPPOSITE the
# waybar, so it always enters moving toward the bar (explicit direction
# suffixes — -50% percentage is unreliable for horizontal special slides):
#   right  -> slide left  (from left, kiri -> kanan)
#   left   -> slide right (from right, kanan -> kiri)
#   bottom -> slidevert top (from top, atas -> bawah)
#   top    -> slidevert bottom (from bottom, bawah -> atas)

CACHE_FILE="$HOME/.config/waybar/.current_position"
CONFIG_FILE="$HOME/.config/waybar/config.jsonc"
DOTS_CONFIG_FILE="$HOME/dots/waybar/config.jsonc"

DOTS_HYPR="$HOME/dots/hypr/modules"
LIVE_HYPR="$HOME/.config/hypr/modules"

get_current_pos() {
    if [[ -f "$CACHE_FILE" ]]; then
        cat "$CACHE_FILE"
    else
        echo "top"
    fi
}

set_hypr_animations() {
    local target_pos="$1"
    local ws_style special_style special_out_style gesture_dir rofi_style

    case "$target_pos" in
        left|right) ws_style="slidevert" ;;
        *)          ws_style="slide" ;;
    esac

    case "$target_pos" in
        right)  special_style="slide left" ;;
        left)   special_style="slide right" ;;
        bottom) special_style="slidevert top" ;;
        top)    special_style="slidevert bottom" ;;
    esac

    # Keluar ke arah asal masuk (suffix OUT = arah gerak keluar, kebalikan In)
    case "$target_pos" in
        right)  special_out_style="slide right" ;;
        left)   special_out_style="slide left" ;;
        bottom) special_out_style="slidevert bottom" ;;
        top)    special_out_style="slidevert top" ;;
    esac

    # Rofi mengikuti posisi waybar (kiri -> dari kanan, kanan -> dari kiri)
    case "$target_pos" in
        right)  rofi_style="slide left" ;;
        left)   rofi_style="slide right" ;;
        *)      rofi_style="slide" ;;
    esac

    case "$target_pos" in
        left|right) gesture_dir="vertical" ;;
        *)          gesture_dir="horizontal" ;;
    esac

    python3 - "$ws_style" "$special_style" "$special_out_style" "$rofi_style" "$gesture_dir" <<'PY'
import re, os, sys

ws_style, special_style, special_out_style, rofi_style, gesture_dir = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5]

for base in (os.path.expanduser('~/dots/hypr/modules'), os.path.expanduser('~/.config/hypr/modules')):
    deco = os.path.join(base, 'decorations.lua')
    if os.path.exists(deco):
        with open(deco, encoding='utf-8') as f:
            content = f.read()
        content = re.sub(r'(leaf = "workspaces"[^\n]*?style = ")[^"]*"',
                         r'\g<1>' + ws_style + '"', content)
        content = re.sub(r'(leaf = "specialWorkspace",[^\n]*?style = ")[^"]*"',
                         r'\g<1>' + special_style + '"', content)
        if 'leaf = "specialWorkspaceOut"' not in content:
            anchor = 'leaf = "specialWorkspace",'
            idx = content.find(anchor)
            if idx != -1:
                nl = content.find('\n', idx)
                insert = '\nhl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 4, bezier = "easeOutQuint", style = "' + special_out_style + '" })'
                content = content[:nl + 1] + insert + content[nl + 1:]
        else:
            content = re.sub(r'(leaf = "specialWorkspaceOut"[^\n]*?style = ")[^"]*"',
                             r'\g<1>' + special_out_style + '"', content)
        with open(deco, 'w', encoding='utf-8') as f:
            f.write(content)

    wr = os.path.join(base, 'windowrules.lua')
    if os.path.exists(wr):
        with open(wr, encoding='utf-8') as f:
            content = f.read()
        if 'rofi-anim' in content:
            content = re.sub(r'(name\s*=\s*"rofi-anim"[\s\S]*?animation\s*=\s*")[^"]*(")',
                             r'\g<1>' + rofi_style + r'\g<2>', content)
        else:
            block = ('\n-- Rofi layer (wayland backend: di-spawn tanpa DISPLAY di launcher.py) -- arah ikut posisi waybar\n'
                     'hl.layer_rule({\n'
                     '    name      = "rofi-anim",\n'
                     '    match     = { namespace = "rofi" },\n'
                     '    animation = "' + rofi_style + '",\n'
                     '})\n')
            content += block
        with open(wr, 'w', encoding='utf-8') as f:
            f.write(content)

    inp = os.path.join(base, 'input.lua')
    if os.path.exists(inp):
        with open(inp, encoding='utf-8') as f:
            content = f.read()
        content = re.sub(r'(direction = ")[^"]*"',
                         r'\g<1>' + gesture_dir + '"', content)
        with open(inp, 'w', encoding='utf-8') as f:
            f.write(content)
PY

    hyprctl reload >/dev/null 2>&1 || true
}

set_position() {
    local target_pos="$1"

    case "$target_pos" in
        top|bottom|left|right) ;;
        *) echo "Invalid position: $target_pos"; exit 1 ;;
    esac

    local mon_h
    mon_h=$(hyprctl monitors -j 2>/dev/null | python3 -c "import json,sys
try:
    print(json.load(sys.stdin)[0]['height'])
except Exception:
    print(1080)")

    python3 -c "
import re, os

def update_waybar_config(filepath, pos):
    if not os.path.exists(filepath):
        return
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    content = re.sub(r'\"position\":\s*\"[^\"]+\"', f'\"position\": \"{pos}\"', content)

    no_border = False
    marker = os.path.expanduser('~/.config/scripts/.border-mode')
    if os.path.exists(marker):
        with open(marker, 'r') as mf:
            no_border = mf.read().strip() == 'noborder'

    if pos in ('left', 'right'):
        # Vertical bar: height mirrors the horizontal width (1000 centered in
        # border mode, full monitor height in no-border mode); the 37px width
        # is mandatory regardless of border mode.
        bar_h = $mon_h if no_border else 1000
        content = re.sub(r'\"height\":\s*\d+', f'\"height\": {bar_h}', content)
        if '\"width\"' not in content:
            content = re.sub(r'(\"height\":\s*\d+)\s*,?', r'\1,\n    \"width\": 37,', content)
        else:
            content = re.sub(r'\"width\":\s*\d+', '\"width\": 37', content)
        if '\"rotate\": 270' not in content:
            content = re.sub(r'(\"clock\":\s*\{)', r'\1\n    \"rotate\": 270,', content)
    else:
        content = re.sub(r'\"height\":\s*\d+', '\"height\": 37', content)
        if no_border:
            content = re.sub(r'\"width\":\s*\d+\s*,?\n', '', content)
        else:
            if not re.search(r'\"width\"', content):
                content = re.sub(r'(\"height\":\s*\d+)\s*,?', r'\1,\n    \"width\": 1000,', content)
            else:
                content = re.sub(r'\"width\":\s*\d+', '\"width\": 1000', content)
        content = re.sub(r'\"rotate\":\s*270,\s*', '', content)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

update_waybar_config('$CONFIG_FILE', '$target_pos')
update_waybar_config('$DOTS_CONFIG_FILE', '$target_pos')
" 2>/dev/null || true

    echo "$target_pos" > "$CACHE_FILE"

    # Hyprland animations/gesture follow the bar position (file + reload,
    # since hyprctl eval dispatch does not work reliably in this session).
    set_hypr_animations "$target_pos"

    # Reload the bar in place (new position/style) — unless it is hidden,
    # in which case it stays hidden and picks up the change on next show.
    bash "$HOME/.config/scripts/waybar-hide.sh" apply
}

cmd_cycle() {
    local cur
    cur=$(get_current_pos)
    case "$cur" in
        top)    set_position "right" ;;
        right)  set_position "bottom" ;;
        bottom) set_position "left" ;;
        left)   set_position "top" ;;
        *)      set_position "top" ;;
    esac
}

cmd_menu() {
    local cur
    cur=$(get_current_pos)
    local selected
    selected=$(printf "󰋜  Top (Horizontal)\n󰋚  Right (Vertical)\n󰋙  Bottom (Horizontal)\n󰋛  Left (Vertical)" | rofi -dmenu -i -p "Waybar Position:")
    [[ -z "$selected" ]] && exit 0
    case "$selected" in
        *"Top"*)    set_position "top" ;;
        *"Right"*)  set_position "right" ;;
        *"Bottom"*) set_position "bottom" ;;
        *"Left"*)   set_position "left" ;;
    esac
}

cmd_init() {
    local cur
    cur=$(get_current_pos)
    set_position "$cur"
}

case "${1-cycle}" in
    init)   cmd_init ;;
    cycle)  cmd_cycle ;;
    menu)   cmd_menu ;;
    top|bottom|left|right) set_position "$1" ;;
    *) echo "Usage: waybar-position.sh {init|cycle|menu|top|bottom|left|right}"; exit 1 ;;
esac