#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------
#  dots installer — Hyprland rice, monochrome dark theme
#  Requires: Arch Linux (or derivative) with sudo
#  Usage:    ./install.sh [--check]
#  --check   Dry-run: show what would be done without making changes
# ---------------------------------------------------------------

DRY_RUN=0
[[ "${1:-}" == "--check" ]] && DRY_RUN=1

RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[1;33m'
CYN='\033[0;36m'
RST='\033[0m'

log()  { printf "${GRN}[dots]${RST} %s\n" "$*"; }
warn() { printf "${YLW}[dots]${RST} %s\n" "$*"; }
err()  { printf "${RED}[dots]${RST} %s\n" "$*"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}"

FAILED=()
step_ok() { log "  ✓ $1"; }
step_fail() { warn "  ✗ $1"; FAILED+=("$1"); }

if [[ "$DRY_RUN" -eq 1 ]]; then
    log "=== DRY RUN MODE — no changes will be made ==="
    log ""
    log "This installer would:"
    log "  1. Install official packages: ${OFFICIAL_PKGS[*]:-hyprland waybar mako ...}"
    log "  2. Install AUR packages: sddm-silent-theme + redhat-fonts + voxtype-bin"
    log "  3. Copy configs to $DEST"
    log "  4. Enable user services: swayosd-server, voxtype-bin (gpu + whisper-small model)"
    log "  5. Enable system services: networkd, resolved, iwd, bluetooth"
    log "  6. Setup SDDM, PostgreSQL, MariaDB, UFW, plocate"
    log "  7. Build + install fetch from source"
    log "  8. Configure nix (sandbox=false for DNS)"
    log ""
    log "Run without --check to execute."
    exit 0
fi

# ---------------------------------------------------------------
#  1. Environment checks
# ---------------------------------------------------------------
[[ $(id -u) -eq 0 ]] && err "Do not run this as root. Run it as your regular user."
command -v pacman >/dev/null || err "This installer only supports Arch-based distros."
command -v sudo >/dev/null || err "sudo is required."
sudo -v

# disk space check (minimum 5 GB free on /)
AVAIL_KB=$(df / --output=avail | tail -1 | tr -d ' ')
if [[ "$AVAIL_KB" -lt 5242880 ]]; then
    warn "Low disk space: $(( AVAIL_KB / 1048576 )) GB free (recommended: 5 GB minimum)"
    printf "Continue anyway? [y/N] "
    read -r REPLY
    [[ "$REPLY" =~ ^[Yy]$ ]] || exit 1
fi

# ---------------------------------------------------------------
#  2. Package lists
# ---------------------------------------------------------------
OFFICIAL_PKGS=(
    hyprland hypridle hyprlock waybar mako rofi
    kitty ghostty cliphist grim slurp satty
    jq playerctl pamixer btop cava qt6ct
    bluez bluez-utils iwd sddm
    polkit-kde-agent bluetui wiremix impala
    swayosd awww
    hyprpicker tesseract tesseract-data-eng libnotify bc nautilus
    brightnessctl
    wl-clipboard wtype wireplumber pipewire-pulse
    ttf-jetbrains-mono-nerd noto-fonts ttf-dejavu
    ttf-material-symbols-variable
    adw-gtk-theme papirus-icon-theme kvantum
    obs-studio cmatrix tree chafa mpv imv
    gnome-disk-utility eza xdg-user-dirs
    fastfetch zip unzip
    chromium firefox
    neovim xdg-desktop-portal-hyprland
    imagemagick os-prober
    plocate
    postgresql mariadb
    ufw
)

AUR_PKGS=(
    sddm-silent-theme
    redhat-fonts
)

# voxtype package selected dynamically after GPU detection in section 4
AUR_PKGS_INTERACTIVE=()

# ---------------------------------------------------------------
#  3. AUR helper (install BOTH paru and yay)
# ---------------------------------------------------------------
log "Ensuring AUR helpers (paru + yay)..."
if ! command -v paru >/dev/null 2>&1 && ! command -v yay >/dev/null 2>&1; then
    log "No AUR helper found. Installing paru first..."
    sudo pacman -S --needed --noconfirm base-devel git rust
    git clone https://aur.archlinux.org/paru.git /tmp/paru-bin
    (cd /tmp/paru-bin && makepkg -si --noconfirm)
    rm -rf /tmp/paru-bin
fi

if ! command -v yay >/dev/null 2>&1; then
    log "Installing yay via paru..."
    paru -S --needed --noconfirm yay
fi

if ! command -v paru >/dev/null 2>&1; then
    log "Installing paru via yay..."
    yay -S --needed --noconfirm paru
fi

command -v paru >/dev/null 2>&1 && AUR_HELPER="paru" || AUR_HELPER="yay"
log "Using AUR helper: $AUR_HELPER (paru and yay both installed)"

# ---------------------------------------------------------------
#  4. Install packages
# ---------------------------------------------------------------
log "[1/6] Installing official packages..."
if sudo pacman -S --needed --noconfirm "${OFFICIAL_PKGS[@]}"; then
    step_ok "official packages"
else
    step_fail "official packages"
fi

log "[2/6] Installing AUR packages..."

# Detect GPU → pick the right voxtype package
log "Detecting GPU..."
GPU_VENDOR="unknown"
if lspci 2>/dev/null | grep -qi nvidia; then
    GPU_VENDOR="nvidia"
    VOXTYPE_PKG="voxtype-cuda"
    warn "  NVIDIA GPU detected — voxtype-cuda (CUDA). Ensure nvidia-dkms + DRM modesetting."
elif lspci 2>/dev/null | grep -qi 'amd\|radeon\|ati'; then
    GPU_VENDOR="amd"
    VOXTYPE_PKG="voxtype-bin"
    log "  AMD GPU detected — voxtype-bin (Vulkan)."
elif lspci 2>/dev/null | grep -qi 'intel\|integrated\|i915'; then
    GPU_VENDOR="intel"
    VOXTYPE_PKG="voxtype-bin"
    log "  Intel GPU detected — voxtype-bin (Vulkan/CPU)."
else
    VOXTYPE_PKG="voxtype-bin"
    log "  GPU not detected — voxtype-bin (CPU inference)."
fi

# Install non-interactive AUR packages first
if [[ ${#AUR_PKGS[@]} -gt 0 ]]; then
    if $AUR_HELPER -S --needed --noconfirm "${AUR_PKGS[@]}"; then
        step_ok "AUR packages"
    else
        step_fail "AUR packages"
    fi
fi

# voxtype: package depends on GPU (cuda for NVIDIA, bin for AMD/Intel/other).
# Installed separately since it's a multi-provider AUR package
# (prompt would block --noconfirm in the combined install).
AUR_PKGS_INTERACTIVE=("$VOXTYPE_PKG")
log "  -> voxtype ($VOXTYPE_PKG)"
if [[ ${#AUR_PKGS_INTERACTIVE[@]} -gt 0 ]]; then
    if $AUR_HELPER -S --needed --noconfirm "${AUR_PKGS_INTERACTIVE[@]}"; then
        step_ok "voxtype"
    else
        step_fail "voxtype"
    fi
fi

# ---------------------------------------------------------------
#  5. Copy configs with safe auto-backup
# ---------------------------------------------------------------
BACKUP_DIR="$HOME/.config.backup-$(date +%Y%m%d_%H%M%S)"
log "[3/6] Creating safety backup in $BACKUP_DIR and copying configs to $DEST"
mkdir -p "$BACKUP_DIR"
for item in hypr scripts waybar rofi mako kitty swayosd btop cava ghostty qt6ct gtk-3.0 gtk-4.0 obs-studio nvim voxtype Kvantum; do
    if [[ -d "$DEST/$item" ]]; then
        cp -r "$DEST/$item" "$BACKUP_DIR/" 2>/dev/null || true
    fi
done

# rollback trap: restore from backup if script fails critically
rollback() {
    if [[ -d "$BACKUP_DIR" ]]; then
        warn "Install failed — restoring configs from $BACKUP_DIR"
        for item in "$BACKUP_DIR"/*; do
            name=$(basename "$item")
            rm -rf "$DEST/$name" 2>/dev/null || true
            cp -r "$item" "$DEST/$name" 2>/dev/null || true
        done
        log "Configs restored. Check $BACKUP_DIR for details."
    fi
}
trap rollback ERR

copy_to() { # $1=src  $2=dst
    echo "  -> $2"
    mkdir -p "$DEST/$2"
    cp -r "$SCRIPT_DIR/$1/." "$DEST/$2/"
}
copy_to hypr           hypr
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
copy_to obs-studio     obs-studio
copy_to nvim           nvim
copy_to voxtype        voxtype
copy_to Kvantum        Kvantum
copy_to nix            nix

chmod +x "$DEST"/scripts/*.sh 2>/dev/null || true

# replace __HOME__ placeholder in qt6ct config
sed -i "s|__HOME__|$HOME|g" "$DEST/qt6ct/qt6ct.conf" 2>/dev/null || true
step_ok "configs copied"

# copy nix config (nix-command flakes, sandbox off for DNS in flake fetch)
log "  -> fetch"
if [[ ! -f "$HOME/.local/bin/fetch" ]]; then
    if git clone https://github.com/areofyl/fetch.git /tmp/fetch-build 2>/dev/null && \
       (cd /tmp/fetch-build && make && PREFIX="$HOME/.local" make install) 2>/dev/null; then
        rm -rf /tmp/fetch-build
        step_ok "fetch"
    else
        rm -rf /tmp/fetch-build
        step_fail "fetch"
    fi
else
    step_ok "fetch (already installed)"
fi

# copy nix config (nix-command flakes, sandbox off for DNS in flake fetch)
log "  -> nix"
mkdir -p "$DEST/nix"
cp "$SCRIPT_DIR/nix/nix.conf" "$DEST/nix/nix.conf"
sudo tee /etc/nix/nix.conf >/dev/null <<'NIXCONF'
build-users-group = nixbld
experimental-features = nix-command flakes
sandbox = false
NIXCONF
sudo systemctl restart nix-daemon 2>/dev/null || true
step_ok "nix config"

# ---------------------------------------------------------------
#  6. User services
# ---------------------------------------------------------------
log "[4/6] Enabling user services..."
systemctl --user daemon-reload
if systemctl --user enable --now swayosd-server.service 2>/dev/null; then
    step_ok "swayosd-server"
else
    step_fail "swayosd-server"
fi

# voxtype: preflight setup (input group, GPU, models) BEFORE starting daemon
if command -v voxtype >/dev/null 2>&1; then
    log "  -> voxtype setup (input group, GPU, model)"
    if ! id -nG | tr ' ' '\n' | grep -qx input; then
        sudo usermod -aG input "$USER" 2>/dev/null
        warn "  added $USER to the 'input' group — re-login for evdev hotkeys"
    fi
    sudo voxtype setup gpu --enable 2>/dev/null || true
    # download Whisper small (multilingual: Indonesian + English) + VAD model
    voxtype setup --download --model small --quiet 2>/dev/null || \
        warn "  model download failed (run: voxtype setup --download --model small)"
    voxtype setup vad 2>/dev/null || true
    step_ok "voxtype (gpu + models)"
else
    warn "  voxtype binary not found"
fi

if systemctl --user enable --now voxtype.service 2>/dev/null; then
    step_ok "voxtype"
else
    step_fail "voxtype"
fi

# swayosd needs write access to /sys/class/backlight/*/brightness,
# which is group-writable by the 'video' group (see 99-swayosd.rules).
if ! id -nG | tr ' ' '\n' | grep -qx video; then
    sudo usermod -aG video "$USER"
    warn "  added $USER to the 'video' group — re-login for brightness keys to work"
fi

# ---------------------------------------------------------------
#  7. System services (systemd-networkd / iwd / bluetooth)
# ---------------------------------------------------------------
log "[5/6] Enabling system services..."

# systemd-networkd interface configs (Ethernet / Wi-Fi / WWAN via iwd)
sudo mkdir -p /etc/systemd/network
for nw in 20-ethernet.network 20-wlan.network 20-wwan.network; do
    if [[ -f "$SCRIPT_DIR/networkd/$nw" ]]; then
        sudo cp "$SCRIPT_DIR/networkd/$nw" "/etc/systemd/network/$nw"
    fi
done

sudo systemctl enable --now systemd-networkd 2>/dev/null || true
sudo systemctl enable --now systemd-resolved 2>/dev/null || true
sudo systemctl enable --now iwd 2>/dev/null || true
sudo systemctl enable --now bluetooth 2>/dev/null || true
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf 2>/dev/null || true
step_ok "system services"

# ---------------------------------------------------------------
#  8. SDDM (theme + config + sudoers for wallpaper sync)
# ---------------------------------------------------------------
log "[6/6] Setting up SDDM, databases, firewall, locate..."

sudo mkdir -p /etc/sddm.conf.d
if [[ -f /usr/share/sddm/themes/silent/Main.qml ]]; then
    sudo tee /etc/sddm.conf.d/silent-theme.conf >/dev/null <<'EOF'
[General]
GreeterEnvironment=QML2_IMPORT_PATH=/usr/share/sddm/themes/silent/components/,QT_IM_MODULE=qtvirtualkeyboard
InputMethod=qtvirtualkeyboard

[Theme]
Current=silent
EOF
    sudo systemctl enable --now sddm 2>/dev/null || true

    # Allow sddm-sync.sh (runs as root via sudo) to read the user's wallpaper cache.
    SUDOERS_LINE="$USER ALL=(root) NOPASSWD: $DEST/scripts/sddm-sync.sh"
    if ! sudo grep -qs "sddm-sync.sh" /etc/sudoers.d/sddm-sync 2>/dev/null; then
        echo "$SUDOERS_LINE" | sudo tee /etc/sudoers.d/sddm-sync >/dev/null
        sudo chmod 440 /etc/sudoers.d/sddm-sync
    fi
    step_ok "SDDM"
else
    step_fail "SDDM (sddm-silent-theme not found)"
fi

# ---------------------------------------------------------------
#  9. PostgreSQL — create user role matching login user
# ---------------------------------------------------------------
log "  -> PostgreSQL"
# init data directory first if missing (Arch: use initdb directly, no postgresql-setup)
if [[ ! -f /var/lib/postgres/data/PG_VERSION ]]; then
    sudo -u postgres /usr/bin/initdb -D /var/lib/postgres/data --locale=C.UTF-8 -E UTF8 2>/dev/null || \
        warn "  PostgreSQL initdb failed"
fi
if sudo systemctl enable --now postgresql 2>/dev/null; then
    if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$USER'" 2>/dev/null | grep -q 1; then
        sudo -u postgres createuser --superuser "$USER" 2>/dev/null || true
    fi
    PG_HBA="/var/lib/postgres/data/pg_hba.conf"
    if [[ -f "$PG_HBA" ]]; then
        if ! sudo grep -qs "^local.*all.*$USER.*peer" "$PG_HBA" 2>/dev/null; then
            echo "local all $USER peer" | sudo tee -a "$PG_HBA" >/dev/null
            echo "host  all $USER 127.0.0.1/32 md5" | sudo tee -a "$PG_HBA" >/dev/null
            echo "host  all $USER ::1/128 md5" | sudo tee -a "$PG_HBA" >/dev/null
            sudo systemctl restart postgresql 2>/dev/null || true
        fi
    fi
    step_ok "PostgreSQL"
else
    step_fail "PostgreSQL"
fi

# ---------------------------------------------------------------
#  10. MariaDB — create user role matching login user
# ---------------------------------------------------------------
log "  -> MariaDB"
# init data directory first if missing
if [[ ! -d /var/lib/mysql/mysql ]]; then
    sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql 2>/dev/null || true
fi
if sudo systemctl enable --now mariadb 2>/dev/null; then
    if ! sudo mariadb -e "SELECT User FROM mysql.user WHERE User='$USER'" 2>/dev/null | grep -q "$USER"; then
        sudo mariadb -e "CREATE USER '$USER'@'localhost' IDENTIFIED BY ''; GRANT ALL PRIVILEGES ON *.* TO '$USER'@'localhost' WITH GRANT OPTION; FLUSH PRIVILEGES;" 2>/dev/null || true
    fi
    step_ok "MariaDB"
else
    step_fail "MariaDB"
fi

# ---------------------------------------------------------------
#  11. UFW firewall
# ---------------------------------------------------------------
log "  -> UFW"
if sudo ufw --force enable 2>/dev/null && \
   sudo ufw default deny incoming 2>/dev/null && \
   sudo ufw default allow outgoing 2>/dev/null && \
   sudo ufw allow 22/tcp 2>/dev/null && \
   sudo ufw allow 80/tcp 2>/dev/null && \
   sudo ufw allow 443/tcp 2>/dev/null; then
    sudo systemctl enable --now ufw 2>/dev/null || true
    step_ok "UFW"
else
    step_fail "UFW"
fi

# ---------------------------------------------------------------
#  12. plocate — updatedb
# ---------------------------------------------------------------
log "  -> plocate"
sudo updatedb 2>/dev/null || true
if [[ ! -f /etc/systemd/system/updatedb.timer ]]; then
    sudo tee /etc/systemd/system/updatedb.timer >/dev/null <<'EOF'
[Unit]
Description=Update locate database weekly

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
EOF
    sudo tee /etc/systemd/system/updatedb.service >/dev/null <<'EOF'
[Unit]
Description=Update locate database

[Service]
Type=oneshot
ExecStart=/usr/bin/updatedb
EOF
    sudo systemctl enable --now updatedb.timer 2>/dev/null || true
fi
step_ok "plocate"

# ---------------------------------------------------------------
#  13. Misc: bashrc, user dirs, default wallpaper
# ---------------------------------------------------------------
log "Installing bashrc, user directories, wallpaper..."

if [[ -f "$SCRIPT_DIR/bashrc" ]]; then
    cp "$SCRIPT_DIR/bashrc" "$HOME/.bashrc"
    log "  installed ~/.bashrc from repo (aliases + eza icons)"
fi

for d in Downloads Documents Music Pictures Videos Projects; do
    mkdir -p "$HOME/$d"
done
command -v xdg-user-dirs-update >/dev/null 2>&1 && xdg-user-dirs-update 2>/dev/null || true

mkdir -p "$HOME/Pictures/Wallpapers"
if [[ -d "$SCRIPT_DIR/wallpapers" ]]; then
    cp -n "$SCRIPT_DIR/wallpapers/"*.png "$HOME/Pictures/Wallpapers/" 2>/dev/null || true
fi
CACHE_FILE="$DEST/scripts/.current_wallpaper"
if [[ ! -f "$CACHE_FILE" ]]; then
    echo "$HOME/Pictures/Wallpapers/black.png" > "$CACHE_FILE"
fi
step_ok "bashrc + directories + wallpaper"

# ---------------------------------------------------------------
#  14. Verify critical services
# ---------------------------------------------------------------
log "Verifying critical services..."
SVC_OK=0; SVC_FAIL=0
for svc in systemd-networkd systemd-resolved iwd bluetooth; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        SVC_OK=$((SVC_OK + 1))
    else
        warn "  ✗ $svc not running"
        SVC_FAIL=$((SVC_FAIL + 1))
    fi
done
for svc in swayosd-server voxtype; do
    if systemctl --user is-active --quiet "$svc" 2>/dev/null; then
        SVC_OK=$((SVC_OK + 1))
    else
        warn "  ✗ $svc (user) not running"
        SVC_FAIL=$((SVC_FAIL + 1))
    fi
done
log "  Services: $SVC_OK running, $SVC_FAIL not running"

# ---------------------------------------------------------------
#  15. Final summary
# ---------------------------------------------------------------
printf "\n"
if [[ ${#FAILED[@]} -eq 0 ]]; then
    printf "${GRN}════════════════════════════════════════${RST}\n"
    printf "${GRN}  ✓ Installation complete! All OK.${RST}\n"
    printf "${GRN}════════════════════════════════════════${RST}\n"
else
    printf "${YLW}════════════════════════════════════════${RST}\n"
    printf "${YLW}  ⚠ Installation complete with ${#FAILED[@]} failure(s):${RST}\n"
    for f in "${FAILED[@]}"; do
        printf "${RED}    ✗ $f${RST}\n"
    done
    printf "${YLW}════════════════════════════════════════${RST}\n"
    printf "\n"
    printf "${YLW}Re-run the installer to fix failed steps:${RST}\n"
    printf "  ${CYN}./install.sh${RST}\n"
fi

printf "\n"
cat <<EOF
Next steps:
  1. Reload the shell (${CYN}source ~/.bashrc${RST})
  2. Log out, log in from SDDM
  3. Use ${CYN}SUPER+W${RST} (random) / ${CYN}SUPER+SHIFT+W${RST} (picker) for wallpapers

Quick commands:
  ${CYN}fetch${RST}             — 3D spinning logo
  ${CYN}nix develop${RST}       — dev shell (type 'exit' to leave)
  ${CYN}locate <name>${RST}     — find files
  ${CYN}sudo ufw status${RST}   — check firewall
  ${CYN}psql${RST}              — PostgreSQL
  ${CYN}mariadb${RST}           — MariaDB

Notes:
  * Requires Hyprland >= 0.55
  * SDDM mirrors your wallpaper automatically
  * Both paru and yay installed
  * voxtype daemon runs on login (push-to-talk dictation)
EOF
