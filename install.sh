#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------
#  dots installer — Hyprland rice with Material You theming
#  Requires: Arch Linux (or derivative) with sudo
#  Usage:    ./install.sh
# ---------------------------------------------------------------

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

# ---------------------------------------------------------------
#  1. Environment checks
# ---------------------------------------------------------------
[[ $(id -u) -eq 0 ]] && err "Do not run this as root. Run it as your regular user."
command -v pacman >/dev/null || err "This installer only supports Arch-based distros."
command -v sudo >/dev/null || err "sudo is required."
sudo -v

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
    ttf-material-symbols-variable-git
    redhat-fonts
    voxtype
)

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
sudo pacman -S --needed --noconfirm "${OFFICIAL_PKGS[@]}"

log "[2/6] Installing AUR packages..."
$AUR_HELPER -S --needed --noconfirm "${AUR_PKGS[@]}"

# Hardware check (GPU / Platform)
log "Detecting hardware platform..."
if lspci 2>/dev/null | grep -qi nvidia; then
    warn "  NVIDIA GPU detected. Ensure nvidia-dkms and proper DRM modesetting are enabled."
elif lspci 2>/dev/null | grep -qi 'amd\|radeon'; then
    log "  AMD GPU detected."
elif lspci 2>/dev/null | grep -qi intel; then
    log "  Intel GPU detected."
fi

# ---------------------------------------------------------------
#  6. Copy configs with safe auto-backup
# ---------------------------------------------------------------
BACKUP_DIR="$HOME/.config.backup-$(date +%Y%m%d_%H%M%S)"
log "[3/6] Creating safety backup in $BACKUP_DIR and copying configs to $DEST"
mkdir -p "$BACKUP_DIR"
for item in hypr scripts waybar rofi mako kitty swayosd btop cava ghostty qt6ct gtk-3.0 gtk-4.0 obs-studio nvim voxtype Kvantum; do
    if [[ -d "$DEST/$item" ]]; then
        cp -r "$DEST/$item" "$BACKUP_DIR/" 2>/dev/null || true
    fi
done

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

# build clipboard-multi helper (image + text multi-mime clipboard)
log "  -> clipboard-multi"
mkdir -p "$HOME/.local/bin"
cc -O2 -o "$HOME/.local/bin/clipboard-multi" \
    "$SCRIPT_DIR/scripts/clipboard-multi/clipboard-multi.c" \
    "$SCRIPT_DIR/scripts/clipboard-multi/zwlr-client-protocol.c" \
    $(pkg-config --cflags --libs wayland-client)

# build fetch (3D spinning distro logo)
log "  -> fetch"
if [[ ! -f "$HOME/.local/bin/fetch" ]]; then
    git clone https://github.com/areofyl/fetch.git /tmp/fetch-build
    (cd /tmp/fetch-build && make && PREFIX="$HOME/.local" make install)
    rm -rf /tmp/fetch-build
    log "  installed fetch to ~/.local/bin/fetch"
else
    log "  fetch already installed, skipping"
fi

# copy nix config (nix-command flakes, sandbox off for DNS in flake fetch)
log "  -> nix"
mkdir -p "$DEST/nix"
cp "$SCRIPT_DIR/nix/nix.conf" "$DEST/nix/nix.conf"
# system-level nix.conf needs sandbox=false (restricted setting, can't set from user)
sudo tee /etc/nix/nix.conf >/dev/null <<'NIXCONF'
build-users-group = nixbld
experimental-features = nix-command flakes
sandbox = false
NIXCONF
sudo systemctl restart nix-daemon 2>/dev/null || true
log "  /etc/nix/nix.conf updated (sandbox=false for DNS resolution)"

# ---------------------------------------------------------------
#  7. User services
# ---------------------------------------------------------------
log "[4/6] Enabling user services..."
systemctl --user daemon-reload
systemctl --user enable --now graphical-session.target 2>/dev/null || true
systemctl --user enable --now swayosd-server.service 2>/dev/null || true
systemctl --user enable --now voxtype.service 2>/dev/null || true

# swayosd needs write access to /sys/class/backlight/*/brightness,
# which is group-writable by the 'video' group (see 99-swayosd.rules).
if ! id -nG | tr ' ' '\n' | grep -qx video; then
    sudo usermod -aG video "$USER"
    warn "  added $USER to the 'video' group — re-login for brightness keys to work"
fi

# ---------------------------------------------------------------
#  8. System services (systemd-networkd / iwd / bluetooth)
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

# routerd (software AP / router) — unit + NetworkManager keyfile, disabled
# by default: user enables it manually when needed. Config (/etc/routerd.conf)
# is not shipped here — copy routerd/routerd.conf.example as a starting point.
if [[ -f "$SCRIPT_DIR/systemd/system/routerd.service" ]]; then
    sudo cp "$SCRIPT_DIR/systemd/system/routerd.service" /etc/systemd/system/routerd.service
fi
if [[ -f "$SCRIPT_DIR/NetworkManager/conf.d/90-routerd.conf" ]]; then
    sudo mkdir -p /etc/NetworkManager/conf.d
    sudo cp "$SCRIPT_DIR/NetworkManager/conf.d/90-routerd.conf" /etc/NetworkManager/conf.d/90-routerd.conf
fi

# ---------------------------------------------------------------
#  9. SDDM (theme + config + sudoers for wallpaper sync)
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
    # Only needed if you want the current wallpaper mirrored to the SDDM login screen.
    SUDOERS_LINE="$USER ALL=(root) NOPASSWD: $DEST/scripts/sddm-sync.sh"
    if ! sudo grep -qs "sddm-sync.sh" /etc/sudoers.d/sddm-sync 2>/dev/null; then
        echo "$SUDOERS_LINE" | sudo tee /etc/sudoers.d/sddm-sync >/dev/null
        sudo chmod 440 /etc/sudoers.d/sddm-sync
        log "  sudoers rule added for sddm-sync.sh"
    fi
else
    warn "  sddm-silent-theme not found in /usr/share/sddm/themes/silent — skipping SDDM setup."
fi

# ---------------------------------------------------------------
#  10. PostgreSQL — create user role matching login user
# ---------------------------------------------------------------
log "  -> PostgreSQL"
sudo systemctl enable --now postgresql 2>/dev/null || true
if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$USER'" | grep -q 1; then
    sudo -u postgres createuser --superuser "$USER" 2>/dev/null || true
    log "  created PostgreSQL superuser role: $USER"
fi
# Allow local passwordless auth via peer (socket) + md5 (tcp)
PG_HBA="/var/lib/postgres/data/pg_hba.conf"
if [[ -f "$PG_HBA" ]]; then
    if ! sudo grep -qs "^local.*all.*$USER.*peer" "$PG_HBA" 2>/dev/null; then
        echo "local all $USER peer" | sudo tee -a "$PG_HBA" >/dev/null
        echo "host  all $USER 127.0.0.1/32 md5" | sudo tee -a "$PG_HBA" >/dev/null
        echo "host  all $USER ::1/128 md5" | sudo tee -a "$PG_HBA" >/dev/null
        sudo systemctl restart postgresql 2>/dev/null || true
        log "  added peer/md5 auth rules for $USER"
    fi
fi

# ---------------------------------------------------------------
#  11. MariaDB — create user role matching login user
# ---------------------------------------------------------------
log "  -> MariaDB"
sudo systemctl enable --now mariadb 2>/dev/null || true
if ! sudo mariadb -e "SELECT User FROM mysql.user WHERE User='$USER'" 2>/dev/null | grep -q "$USER"; then
    sudo mariadb -e "CREATE USER '$USER'@'localhost' IDENTIFIED BY ''; GRANT ALL PRIVILEGES ON *.* TO '$USER'@'localhost' WITH GRANT OPTION; FLUSH PRIVILEGES;" 2>/dev/null || true
    log "  created MariaDB user: $USER (localhost, no password)"
fi

# ---------------------------------------------------------------
#  12. UFW firewall
# ---------------------------------------------------------------
log "  -> UFW firewall"
sudo ufw --force enable 2>/dev/null || true
sudo ufw default deny incoming 2>/dev/null || true
sudo ufw default allow outgoing 2>/dev/null || true
sudo ufw allow 22/tcp 2>/dev/null || true   # SSH
sudo ufw allow 80/tcp 2>/dev/null || true   # HTTP
sudo ufw allow 443/tcp 2>/dev/null || true  # HTTPS
sudo systemctl enable --now ufw 2>/dev/null || true
log "  UFW enabled: deny incoming, allow outgoing, ports 22/80/443 open"

# ---------------------------------------------------------------
#  13. plocate — updatedb
# ---------------------------------------------------------------
log "  -> plocate database"
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
    log "  weekly updatedb timer enabled"
fi

# ---------------------------------------------------------------
#  14. Misc: bashrc, user dirs, default wallpaper
# ---------------------------------------------------------------
log "Installing bashrc, user directories, wallpaper..."

# Install repo bashrc (no backup — repo is the source of truth)
if [[ -f "$SCRIPT_DIR/bashrc" ]]; then
    cp "$SCRIPT_DIR/bashrc" "$HOME/.bashrc"
    log "  installed ~/.bashrc from repo (aliases + eza icons)"
fi

# Standard user directories (GTK file managers icon them via xdg-user-dirs)
for d in Downloads Documents Music Pictures Videos Projects; do
    mkdir -p "$HOME/$d"
done
command -v xdg-user-dirs-update >/dev/null 2>&1 && xdg-user-dirs-update 2>/dev/null || true
log "  created ~/Downloads ~/Documents ~/Music ~/Pictures ~/Videos ~/Projects"

# Default wallpaper (black.png)
mkdir -p "$HOME/Pictures/Wallpapers"
if [[ -d "$SCRIPT_DIR/wallpapers" ]]; then
    cp -n "$SCRIPT_DIR/wallpapers/"*.png "$HOME/Pictures/Wallpapers/" 2>/dev/null || true
    log "  staged black.png wallpaper in ~/Pictures/Wallpapers/"
fi
CACHE_FILE="$DEST/scripts/.current_wallpaper"
if [[ ! -f "$CACHE_FILE" ]]; then
    echo "$HOME/Pictures/Wallpapers/black.png" > "$CACHE_FILE"
    log "  default black wallpaper staged — it will apply on first Hyprland start"
fi

# ---------------------------------------------------------------
#  11. Done
# ---------------------------------------------------------------
cat <<EOF

${GRN}Installation complete!${RST}

Next steps:
  1. Reload the shell (source ~/.bashrc) — aliases + eza icons + prompt from repo's bashrc
  2. Log out, switch to sddm, log back in
  3. A default wallpaper (black.png) is already staged — it applies on
     first Hyprland start. Drop your own images into ~/Pictures/Wallpapers/
     and use SUPER+W (random) / SUPER+SHIFT+W (picker) to switch.
  4. User directories are ready: ~/Downloads ~/Documents ~/Music ~/Pictures
     ~/Videos ~/Projects (folder icons show in file managers and terminal via eza)

Notes:
  * Requires Hyprland >= 0.55 (config uses the Lua API)
  * Recolor everything after a wallpaper change: run wallpaper.sh
    (SUPER+W random, SUPER+SHIFT+W picker)
  * SDDM theme will mirror your current wallpaper automatically
    (post_hook runs sddm-sync.sh via the sudoers rule above)
  * Both paru and yay are installed; use whichever you prefer.
  * Nix: run 'nix develop' in ~/dots for dev shell (node, python, go, rust, etc.)
  * voxtype daemon is enabled — runs on login for push-to-talk dictation
  * fetch (3D spinning logo) is installed to ~/.local/bin/fetch
  * PostgreSQL + MariaDB: user '$USER' has full access (no sudo needed)
  * UFW firewall enabled: deny incoming, allow outgoing, ports 22/80/443
  * plocate: updatedb runs weekly, use 'locate' to find files
EOF
