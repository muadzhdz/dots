#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}"

copy_to() { # $1=src  $2=dst
    echo "  -> $2"
    if command -v rsync &>/dev/null; then
        rsync -a --quiet "$SCRIPT_DIR/$1/" "$DEST/$2/"
    else
        mkdir -p "$DEST/$2"
        cp -r "$SCRIPT_DIR/$1/." "$DEST/$2/"
    fi
}

echo "[1/4] Copying configs to $DEST"
copy_to hypr           hypr
copy_to matugen        matugen
copy_to scripts        scripts
copy_to waybar         waybar
copy_to rofi           rofi
copy_to mako           mako
copy_to kitty          kitty
copy_to swayosd        swayosd
copy_to systemd/user   systemd/user
copy_to btop           btop
copy_to cava           cava
copy_to ghostty        ghostty
copy_to qt6ct          qt6ct
copy_to gtk/gtk-3.0    gtk-3.0
copy_to gtk/gtk-4.0    gtk-4.0

echo "[2/4] Setting up scripts"
chmod +x "$DEST"/scripts/*.sh || true

echo "[3/4] Enabling swayosd server (user service)"
systemctl --user daemon-reload
systemctl --user enable --now swayosd-server.service

echo "[4/4] Done"
echo
echo "Notes:"
echo "  * Requires Hyprland >= 0.55 (config uses the Lua API)"
echo "  * Put your wallpapers in ~/Pictures/Wallpapers/"
echo "  * Log out / restart Hyprland, then run:"
echo "      ~/.config/scripts/wallpaper.sh init"
echo "  * swayosd is expected to be the custom 24px-icon build"
echo "    (see README). Match the version in this repo if you see odd icons."
