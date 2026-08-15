#!/usr/bin/env bash
set -euo pipefail

# EvoDevo GRUB sync: wallpaper aktif -> wallpapers/default.jpg, lalu rebuild theme.
# Dipanggil root via sudoers NOPASSWD (manual / matugen post_hook).

REAL_USER="${SUDO_USER:-$USER}"
if [[ -z "$REAL_USER" || "$REAL_USER" = "root" ]]; then
    REAL_USER="$(awk -F: '$6 ~ /^\/home\// { print $1; exit }' /etc/passwd)"
fi
HOME_DIR="$(getent passwd "$REAL_USER" | cut -d: -f6)"
CACHE="$HOME_DIR/.config/scripts/.current_wallpaper"
INSTALL_DIR="$HOME_DIR/Downloads/grub-evodevo"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

log() { echo "grub-sync: $*"; }

exec 9>/tmp/grub-sync.lock
flock -n 9 || { log "already running, skipping"; exit 0; }

[[ -f "$CACHE" ]] || { log "no wallpaper cache"; exit 0; }
WALL="$(cat "$CACHE")"
[[ -f "$WALL" ]] || { log "wallpaper missing: $WALL"; exit 0; }

# 1. wallpaper aktif -> crop 1920x1080 -> wallpapers/default.jpg
ffmpeg -y -loglevel error -i "$WALL" \
    -vf "scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080" \
    -q:v 2 "$TMP/default.jpg"
identify "$TMP/default.jpg" >/dev/null
install -m644 "$TMP/default.jpg" "$INSTALL_DIR/wallpapers/default.jpg"

# 2. rebuild theme + grub.cfg
cd "$INSTALL_DIR"
sh install.sh >/dev/null 2>&1 || { log "install.sh failed"; exit 1; }
sync

log "done: $WALL -> evodevo theme"
