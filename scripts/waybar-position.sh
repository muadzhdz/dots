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

    python3 -c "
import re, os

def update_waybar_config(filepath, pos):
    if not os.path.exists(filepath):
        return
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    content = re.sub(r'\"position\":\s*\"[^\"]+\"', f'\"position\": \"{pos}\"', content)

    if pos in ('left', 'right'):
        content = re.sub(r'\"height\":\s*\d+', '\"height\": 1000', content)
        content = re.sub(r'\"width\":\s*\d+', '\"width\": 37', content)
        if '\"rotate\": 270' not in content:
            content = re.sub(r'(\"clock\":\s*\{)', r'\1\n    \"rotate\": 270,', content)
    else:
        content = re.sub(r'\"height\":\s*\d+', '\"height\": 37', content)
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

    # Layers: bars enter from their own edge (no cross-screen travel), old bar fades out
    hyprctl eval 'hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint", style = "slide" })' >/dev/null 2>&1 || true
    hyprctl eval 'hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slide" })' >/dev/null 2>&1 || true
    # layersOut: old bar hides with a fade before the new one enters
    hyprctl eval 'hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })' >/dev/null 2>&1 || true

    # Restart Waybar cleanly: let the old bar hide (layersOut fade) before the new one enters
    if pkill -x waybar 2>/dev/null; then
        while pgrep -x waybar >/dev/null 2>&1; do sleep 0.02; done
        sleep 0.8
    fi
    waybar >/dev/null 2>&1 &
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
