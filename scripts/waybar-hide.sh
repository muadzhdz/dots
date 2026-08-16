#!/usr/bin/env bash
set -euo pipefail

# Waybar hide/show with deterministic state.
# - "start_hidden": true  -> waybar comes up hidden (no flash on restart)
# - "on-sigusr1": "hide"  -> SIGUSR1 is a SET hide (idempotent)
# - "on-sigusr2": "show"  -> SIGUSR2 is a SET show (idempotent)
# The marker file can never drift from the real bar state.

MARKER="$HOME/.config/waybar/.hidden"

is_hidden() {
    [[ -f "$MARKER" ]]
}

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Waybar" "$1"
    fi
}

waybar_ready() {
    hyprctl layers -j 2>/dev/null | grep -q '"waybar"'
}

restart_waybar() {
    if pkill -x waybar 2>/dev/null; then
        while pgrep -x waybar >/dev/null 2>&1; do sleep 0.02; done
        sleep 0.8
    fi
    waybar >/dev/null 2>&1 &
}

# Wait until waybar has fully configured (its layer surface appears, which
# only happens after the portal handshake), then SET it visible.
set_visible() {
    for _ in $(seq 1 45); do
        if waybar_ready; then
            break
        fi
        sleep 1
    done
    sleep 0.5
    pkill -SIGUSR2 waybar 2>/dev/null || true
    sleep 0.5
    pkill -SIGUSR2 waybar 2>/dev/null || true
}

cmd_hide() {
    touch "$MARKER"
    pkill -SIGUSR1 waybar 2>/dev/null || true
    notify "Hidden"
}

cmd_show() {
    rm -f "$MARKER"
    if ! pgrep -x waybar >/dev/null 2>&1; then
        restart_waybar
    fi
    set_visible
    notify "Shown"
}

cmd_toggle() {
    if is_hidden; then
        cmd_show
    else
        cmd_hide
    fi
}

# Called after any waybar restart (wallpaper, border mode, position).
# The bar comes up hidden (start_hidden) — show it only if not hidden.
cmd_apply() {
    if ! is_hidden; then
        set_visible
    fi
}

case "${1-toggle}" in
    toggle) cmd_toggle ;;
    hide)   cmd_hide ;;
    show)   cmd_show ;;
    apply)  cmd_apply ;;
    *) echo "usage: waybar-hide.sh {toggle|hide|show|apply}"; exit 1 ;;
esac