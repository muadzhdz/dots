#!/usr/bin/env bash
set -euo pipefail

# Audio Output/Input Device Switcher via Rofi
# Uses wpctl (PipeWire / WirePlumber)

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Audio Switcher" "$1" -i audio-speakers
    fi
}

mode="${1:-sink}"

if [[ "$mode" == "source" || "$mode" == "mic" ]]; then
    target="Sources"
    title="Audio Input (Mic):"
else
    target="Sinks"
    title="Audio Output:"
fi

# Parse wpctl status
devices=$(python3 -c "
import subprocess, re

out = subprocess.check_output(['wpctl', 'status'], text=True)
section = None
items = []

for line in out.splitlines():
    if 'Sinks:' in line:
        section = 'Sinks'
        continue
    elif 'Sources:' in line:
        section = 'Sources'
        continue
    elif 'Filters:' in line or 'Streams:' in line or 'Video' in line or 'Settings' in line:
        section = None
        continue

    if section == '$target':
        m = re.search(r'([*]?)\s*(\d+)\.\s+([^\[\n]+)', line)
        if m:
            is_active = bool(m.group(1).strip())
            dev_id = m.group(2)
            name = m.group(3).strip()
            prefix = '● ' if is_active else '○ '
            items.append(f'{prefix}{name} (ID: {dev_id})|{dev_id}')

for item in items:
    print(item)
")

[[ -z "$devices" ]] && exit 0

menu_items=$(echo "$devices" | awk -F'|' '{print $1}')
selected=$(echo "$menu_items" | rofi -dmenu -i -p "$title")
[[ -z "$selected" ]] && exit 0

selected_id=$(echo "$devices" | grep -F "$selected" | head -n 1 | awk -F'|' '{print $2}')

if [[ -n "$selected_id" ]]; then
    wpctl set-default "$selected_id"
    clean_name=$(echo "$selected" | sed 's/^[●○] //')
    notify "Switched to: $clean_name"
fi
