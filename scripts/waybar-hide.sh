#!/usr/bin/env bash
set -euo pipefail

# Waybar hide/show toggle with persistent state (survives logout/reboot)
# Source of truth: ~/.config/waybar/.hidden
# All waybar restarts (border-mode.sh, waybar-position.sh) must call "apply"
# so a hidden waybar stays hidden.

MARKER="$HOME/.config/waybar/.hidden"

is_hidden() {
    [[ -f "$MARKER" ]]
}

cmd_toggle() {
    if is_hidden; then
        rm -f "$MARKER"
        if command -v notify-send >/dev/null 2>&1; then
            notify-send "Waybar" "Shown"
        fi
    else
        touch "$MARKER"
        if command -v notify-send >/dev/null 2>&1; then
            notify-send "Waybar" "Hidden"
        fi
    fi
    pkill -SIGUSR1 waybar 2>/dev/null || true
}

waybar_in_layers() {
    hyprctl layers -j 2>/dev/null | grep -q '"waybar"'
}

cmd_apply() {
    if is_hidden; then
        # Wait for the old instance to fully exit (its layer gets unregistered)
        for _ in $(seq 1 30); do
            waybar_in_layers || break
            sleep 0.1
        done
        # Wait for the new instance to register, then hide it
        for _ in $(seq 1 30); do
            if waybar_in_layers; then
                sleep 0.3
                pkill -SIGUSR1 waybar 2>/dev/null || true
                return 0
            fi
            sleep 0.1
        done
    fi
}

case "${1-toggle}" in
    toggle) cmd_toggle ;;
    apply)  cmd_apply ;;
    *) echo "usage: waybar-hide.sh {toggle|apply}"; exit 1 ;;
esac