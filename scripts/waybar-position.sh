#!/usr/bin/env bash

# Waybar Position & Hyprland Workspace Animation Switcher
# Top/Bottom -> Workspaces animation = "slide" (horizontal)
# Left/Right -> Workspaces animation = "slidevert" (vertical)

CACHE_FILE="$HOME/.config/waybar/.current_position"
CONFIG_FILE="$HOME/.config/waybar/config.jsonc"
DOTS_CONFIG_FILE="$HOME/dots/waybar/config.jsonc"

get_current_pos() {
    if [[ -f "$CACHE_FILE" ]]; then
        cat "$CACHE_FILE"
    else
        echo "top"
    fi
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

    # Clear any existing 3-finger swipe gesture first to avoid duplicates/shadowing
    hyprctl eval 'hl.gesture({ fingers = 3, direction = "horizontal", action = "unset" })' >/dev/null 2>&1 || true
    hyprctl eval 'hl.gesture({ fingers = 3, direction = "vertical", action = "unset" })' >/dev/null 2>&1 || true

    if [[ "$target_pos" == "left" || "$target_pos" == "right" ]]; then
        # 3-finger swipe gesture VERTICAL for vertical sidebar
        hyprctl eval 'hl.gesture({ fingers = 3, direction = "vertical", action = "workspace" })' >/dev/null 2>&1 || true
        # Regular workspace transition animation VERTICAL (slidevert)
        hyprctl eval 'hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slidevert" })' >/dev/null 2>&1 || true
        # Special workspace animation HORIZONTAL (slide)
        hyprctl eval 'hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slide" })' >/dev/null 2>&1 || true
        # Rofi: appears from the side opposite the waybar (per-layer rule)
        if [[ "$target_pos" == "left" ]]; then
            hyprctl eval 'hl.layer_rule({ name = "rofi-anim", match = { namespace = "rofi" }, animation = "slide right" })' >/dev/null 2>&1 || true
        else
            hyprctl eval 'hl.layer_rule({ name = "rofi-anim", match = { namespace = "rofi" }, animation = "slide left" })' >/dev/null 2>&1 || true
        fi
    else
        # 3-finger swipe gesture HORIZONTAL for horizontal bar
        hyprctl eval 'hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })' >/dev/null 2>&1 || true
        # Regular workspace transition animation HORIZONTAL (slide)
        hyprctl eval 'hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slide" })' >/dev/null 2>&1 || true
        # Special workspace animation VERTICAL (slidevert)
        hyprctl eval 'hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slidevert" })' >/dev/null 2>&1 || true
        # Rofi: default horizontal slide
        hyprctl eval 'hl.layer_rule({ name = "rofi-anim", match = { namespace = "rofi" }, animation = "slide" })' >/dev/null 2>&1 || true
    fi

    # Layer animations are disabled (decorations.lua) so the bar never
    # flickers when it is reloaded or moved.

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
