#!/usr/bin/env bash
set -euo pipefail

MONITOR=$(hyprctl monitors -j | jq -r '.[].name' | rofi -dmenu -i -p " Monitor: ")
[[ -z $MONITOR ]] && exit 0

MODES=$(hyprctl monitors -j | jq -r --arg m "$MONITOR" '.[] | select(.name == $m) | .availableModes[]' | sed 's/\.[0-9]*Hz//')

MODE=$(printf 'preferred\n%s\n' "$MODES" | rofi -dmenu -i -p " Mode ($MONITOR): ")
[[ -z $MODE ]] && exit 0

SCALE=$(printf '1.0\n1.25\n1.5\n2.0\n2.5\n3.0\n' | rofi -dmenu -i -p " Scale ($MONITOR): ")
[[ -z $SCALE ]] && exit 0

hyprctl eval "hl.monitor({output='$MONITOR',mode='$MODE',position='auto',scale='$SCALE'})"
printf '%s %s %s\n' "$MONITOR" "$MODE" "$SCALE" > "$HOME/.config/hypr/.monitor-cache"
notify-send "Display" "$MONITOR $MODE @ ${SCALE}x" -t 2000
