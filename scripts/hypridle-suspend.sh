#!/bin/bash
# hypridle-suspend.sh
# Dipanggil hypridle saat timeout suspend. Skip suspend jika ada proses penting
# yang sedang berjalan (video/musik, download, CLI agent). Lock & screen off
# tetap jalan; hanya suspend yang dilewati.

LOCKED_BY=""

# 1. Video / musik sedang diputar
if command -v playerctl >/dev/null 2>&1; then
    if playerctl status 2>/dev/null | grep -q "Playing"; then
        LOCKED_BY="playerctl (media playing)"
    fi
fi

# 2. Download browser aktif (file .crdownload yang masih ditulis < 2 menit)
RECENT=$(find "$HOME/Downloads" -maxdepth 1 -name "*.crdownload" -mmin -2 2>/dev/null | head -1)
if [ -n "$RECENT" ]; then
    LOCKED_BY="download browser: $(basename "$RECENT")"
fi

# 3. Proses CLI aktif (download tool, AI agent, package manager)
ACTIVE_PROCS=(
    "wget"
    "curl"
    "aria2"
    "transmission"
    "opencode"
    "kiro-cli"
    "agy"
    "codex"
    "hermes"
    "pacman"
    "yay"
    "paru"
    "nix"
)
for proc in "${ACTIVE_PROCS[@]}"; do
    if pgrep -f "$proc" >/dev/null 2>&1; then
        LOCKED_BY="proses: $proc"
        break
    fi
done

# 4. Python HTTP server aktif
if pgrep -f "python.*http\.server" >/dev/null 2>&1; then
    LOCKED_BY="proses: python -m http.server"
fi

if [ -n "$LOCKED_BY" ]; then
    notify-send -a "hypridle" "Suspend dilewati" "Ada aktivitas: $LOCKED_BY" 2>/dev/null
    exit 0
fi

systemctl suspend