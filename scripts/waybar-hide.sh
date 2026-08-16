#!/usr/bin/env bash
set -euo pipefail

# Waybar hide/show — simple & deterministic:
#   hide = killall -SIGUSR1 (SET "hide" via on-sigusr1)
#   show = restart waybar (comes up visible)
# A hidden waybar is never restarted, so it can never pop back up.
# Restart points (wallpaper/border mode/position) call "apply".

MARKER="$HOME/.config/waybar/.hidden"

is_hidden() {
    [[ -f "$MARKER" ]]
}

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Waybar" "$1"
    fi
}

restart_waybar() {
    if pkill -x waybar 2>/dev/null; then
        while pgrep -x waybar >/dev/null 2>&1; do sleep 0.02; done
        sleep 0.8
    fi
    waybar >/dev/null 2>&1 &
}

cmd_hide() {
    touch "$MARKER"
    pkill -SIGUSR1 waybar 2>/dev/null || true
    notify "Hidden"
}

cmd_show() {
    rm -f "$MARKER"
    restart_waybar
    notify "Shown"
}

cmd_toggle() {
    if is_hidden; then
        cmd_show
    else
        cmd_hide
    fi
}

# Reload the bar in place (SIGUSR2 = reload) unless it is hidden, so new
# style/position/width apply without the bar ever disappearing. Falls back
# to a fresh start if no waybar is running.
cmd_apply() {
    if is_hidden; then
        return
    fi
    if pgrep -x waybar >/dev/null 2>&1; then
        pkill -SIGUSR2 waybar 2>/dev/null || true
    else
        waybar >/dev/null 2>&1 &
    fi
}

case "${1-toggle}" in
    toggle) cmd_toggle ;;
    hide)   cmd_hide ;;
    show)   cmd_show ;;
    apply)  cmd_apply ;;
    *) echo "usage: waybar-hide.sh {toggle|hide|show|apply}"; exit 1 ;;
esac