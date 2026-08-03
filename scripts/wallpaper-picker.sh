#!/usr/bin/env bash
set -euo pipefail
shopt -s inherit_errexit nullglob

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
CACHE_FILE="$HOME/.config/scripts/.current_wallpaper"

rofi_info=${ROFI_INFO-}

if [[ -z "$rofi_info" ]]; then
    printf '\0prompt\x1fWallpaper\n'

    while IFS= read -r -d '' f; do
        name=$(basename "$f")
        name=${name%.*}
        printf '󰸉  %s\0info\x1f%s\n' "$name" "$f"
    done < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.bmp' -o -iname '*.webp' \) -print0 | sort -z)

    exit 0
fi

~/.config/scripts/wallpaper.sh set "$rofi_info"
