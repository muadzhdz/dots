#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$HOME/.config/scripts"
TMP="$(mktemp)"

cleanup() {
    rm -f "$TMP"
}
trap cleanup EXIT

python3 "$SCRIPT_DIR/keybinds.py" > "$TMP"

idx=$(awk -F'\t' '{printf "%-22s %s\n", $1, $2}' "$TMP" \
    | rofi -dmenu -i -format i -p "  Keybinds" -display "  Keybinds")

[[ -z "$idx" ]] && exit 0

cmd=$(awk -F'\t' -v r="$((idx + 1))" 'NR == r { print $3 }' "$TMP")
if [[ -n "$cmd" ]]; then
    setsid bash -c "$cmd" >/dev/null 2>&1 &
    disown
fi
