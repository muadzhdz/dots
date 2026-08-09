#!/usr/bin/env bash
set -euo pipefail

REAL_USER="${SUDO_USER:-$USER}"
HOME_DIR="$(getent passwd "$REAL_USER" | cut -d: -f6)"
CACHE="$HOME_DIR/.config/scripts/.current_wallpaper"
GEN="$HOME_DIR/.config/matugen/generated/sddm.conf"
THEME=/usr/share/sddm/themes/silent

[[ -f "$CACHE" ]] || { echo "sddm-sync: no wallpaper cache"; exit 0; }
WALL=$(cat "$CACHE")
[[ -f "$WALL" ]] || { echo "sddm-sync: wallpaper missing: $WALL"; exit 0; }

ext="${WALL##*.}"
[[ "$ext" =~ ^[a-zA-Z0-9]{1,5}$ ]] || ext=jpg

cp -f "$WALL" "$THEME/backgrounds/current.$ext"
sed -i "s|background = \"current\.jpg\"|background = \"current.$ext\"|g" "$GEN"
cp -f "$GEN" "$THEME/configs/default.conf"
chmod 644 "$THEME/backgrounds/current.$ext" "$THEME/configs/default.conf"

echo "sddm-sync: synced $WALL (current.$ext)"
