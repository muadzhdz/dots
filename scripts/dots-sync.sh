#!/usr/bin/env bash
set -euo pipefail

# dots-sync.sh — Seamless bidirectional / system-to-dots synchronization tool
# Syncs active configs from ~/.config and ~ to ~/dots

DOTS="${1:-$HOME/dots}"
CONFIG="$HOME/.config"

RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[1;33m'
CYN='\033[0;36m'
RST='\033[0m'

log()  { printf "${GRN}[dots-sync]${RST} %s\n" "$*"; }
warn() { printf "${YLW}[dots-sync]${RST} %s\n" "$*"; }
err()  { printf "${RED}[dots-sync]${RST} %s\n" "$*"; exit 1; }

[[ -d "$DOTS" ]] || err "Dots directory not found at $DOTS"

log "Starting synchronization from ~/.config to $DOTS..."

# 1. Sync standard directory mappings
sync_dir() { # $1=src (relative to ~/.config) $2=dst (relative to ~/dots)
    local src="$CONFIG/$1"
    local dst="$DOTS/$2"
    if [[ -d "$src" ]]; then
        mkdir -p "$dst"
        # rsync or cp excluding cache/runtime files
        rsync -av --delete \
            --exclude='.git' \
            --exclude='__pycache__' \
            --exclude='*.log' \
            --exclude='*.txt' \
            --exclude='.current_*' \
            --exclude='.border-*' \
            --exclude='.monitor-cache' \
            --exclude='logs/' \
            --exclude='profiler_data/' \
            --exclude='.sentinel' \
            --exclude='*.wants/' \
            "$src/" "$dst/" >/dev/null
        log "  ✓ synced $1 -> $2"
    fi
}

sync_dir "hypr"           "hypr"
sync_dir "themes"         "themes"
sync_dir "scripts"        "scripts"
sync_dir "waybar"         "waybar"
sync_dir "rofi"           "rofi"
sync_dir "mako"           "mako"
sync_dir "kitty"          "kitty"
sync_dir "swayosd"        "swayosd"
sync_dir "systemd/user"   "systemd/user"
sync_dir "btop"           "btop"
sync_dir "cava"           "cava"
sync_dir "ghostty"        "ghostty"
sync_dir "qt6ct"          "qt6ct"
sync_dir "gtk-3.0"        "gtk/gtk-3.0"
sync_dir "gtk-4.0"        "gtk/gtk-4.0"
sync_dir "obs-studio"     "obs-studio"
sync_dir "nvim"           "nvim"
sync_dir "voxtype"        "voxtype"
sync_dir "fastfetch"      "fastfetch"
sync_dir "Kvantum"        "Kvantum"

# 2. Sync bashrc
if [[ -f "$HOME/.bashrc" ]]; then
    cp "$HOME/.bashrc" "$DOTS/bashrc"
    log "  ✓ synced ~/.bashrc -> bashrc"
fi

log "Synchronization complete!"

# 3. Git status summary
printf "\n${CYN}=== Git Status in %s ===${RST}\n" "$DOTS"
git -C "$DOTS" status -s

printf "\n${GRN}Done! To commit changes: cd %s && git add -A && git commit -m \"sync: ...\"${RST}\n" "$DOTS"
