#!/usr/bin/env bash
set -euo pipefail

REAL_USER="${SUDO_USER:-$USER}"
HOME_DIR="$(getent passwd "$REAL_USER" | cut -d: -f6)"
CACHE="$HOME_DIR/.config/scripts/.current_wallpaper"
THEME=/usr/share/sddm/themes/silent

[[ -f "$CACHE" ]] || { echo "sddm-sync: no wallpaper cache"; exit 0; }
WALL=$(cat "$CACHE")
[[ -f "$WALL" ]] || { echo "sddm-sync: wallpaper missing: $WALL"; exit 0; }

if [[ -d "$THEME/backgrounds" ]]; then
    # Copy wallpaper to all standard current formats
    cp -f "$WALL" "$THEME/backgrounds/current.png" 2>/dev/null || true
    cp -f "$WALL" "$THEME/backgrounds/current.jpg" 2>/dev/null || true
    cp -f "$WALL" "$THEME/backgrounds/current.jpeg" 2>/dev/null || true
    chmod 644 "$THEME/backgrounds"/current.* 2>/dev/null || true
fi

# Update SDDM default.conf to use current.png without heavy blur
if [[ -f "$THEME/configs/default.conf" ]]; then
    python3 -c "
import re
path = '$THEME/configs/default.conf'
with open(path, 'r') as f:
    content = f.read()
content = re.sub(r'background = \"[^\"]+\"', 'background = \"current.png\"', content)
content = re.sub(r'blur = \d+', 'blur = 0', content)
with open(path, 'w') as f:
    f.write(content)
" 2>/dev/null || true
fi

echo "sddm-sync: synced $WALL to SDDM"
