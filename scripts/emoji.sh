#!/bin/bash
set -euo pipefail

DATA_FILE="${HOME}/.config/scripts/emoji_data.txt"

if ! command -v rofi &>/dev/null || ! command -v wl-copy &>/dev/null; then
    notify-send "Error" "Rofi or wl-copy is missing." -u critical
    exit 1
fi

if [[ ! -f $DATA_FILE ]]; then
    notify-send "Error" "emoji_data.txt not found" -u critical
    exit 1
fi

selected_emoji=$( \
    rofi \
    -dmenu \
    -i \
    -theme "$HOME/.config/rofi/config.rasi" \
    -no-show-icons \
    -font "Noto Color Emoji 11, JetBrainsMono Nerd Font 11" \
    -p "Emoji" \
    -mesg "<i>Hit Enter to copy</i>" \
    < "$DATA_FILE" \
    | awk '{print $1}')

if [[ -n $selected_emoji ]]; then
    echo -n "$selected_emoji" | wl-copy
    notify-send "Copied" "$selected_emoji copied to clipboard" -t 1000
fi
