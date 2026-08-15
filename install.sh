#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------
#  dots installer — Hyprland rice with matugen Material You theming
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
    bluez bluez-utils networkmanager iwd sddm
    polkit-kde-agent bluetui wiremix impala
    matugen swayosd awww
    hyprpicker tesseract tesseract-data-eng libnotify bc nautilus
    brightnessctl
    wl-clipboard wireplumber pipewire-pulse
    ttf-jetbrains-mono-nerd noto-fonts ttf-dejavu
    adw-gtk-theme papirus-icon-theme kvantum
    obs-studio cmatrix tree chafa mpv imv
    gnome-disk-utility eza xdg-user-dirs
    fastfetch zip unzip
    chromium firefox
    neovim xdg-desktop-portal-hyprland
    imagemagick os-prober
)

AUR_PKGS=(
    sddm-silent-theme
    ttf-material-symbols-variable-git
    redhat-fonts
    yaru-gtk-theme
    zen-browser-bin
    helium-browser-bin
    tor-browser-bin
    visual-studio-code-bin
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
#  4. Browser selection (multi-select, one or many)
# ---------------------------------------------------------------
choose_browsers() {
    printf "\n${CYN}Pick browser(s) to install (comma-separated, e.g. '1,3,5'):${RST}\n"
    printf "  ${GRN}1${RST}) chromium\n"
    printf "  ${GRN}2${RST}) firefox\n"
    printf "  ${GRN}3${RST}) zen-browser\n"
    printf "  ${GRN}4${RST}) helium-browser\n"
    printf "  ${GRN}5${RST}) tor-browser\n"
    printf "  ${YLW}0${RST}) none\n"
    printf "  ${CYN}> ${RST}"
    read -r answer
    answer="${answer// /}"
    [[ -z "$answer" ]] && return 0
    [[ "$answer" == "all" ]] && { OFFICIAL_PKGS+=("chromium" "firefox"); AUR_PKGS+=("zen-browser-bin" "helium-browser-bin" "tor-browser-bin"); return 0; }

    local n
    IFS=',' read -r -a nums <<< "$answer"
    for n in "${nums[@]}"; do
        case "$n" in
            0) return 0 ;;
            1) OFFICIAL_PKGS+=("chromium") ;;
            2) OFFICIAL_PKGS+=("firefox") ;;
            3) AUR_PKGS+=("zen-browser-bin") ;;
            4) AUR_PKGS+=("helium-browser-bin") ;;
            5) AUR_PKGS+=("tor-browser-bin") ;;
            *) warn "Skipping invalid choice: $n" ;;
        esac
    done
}
choose_browsers

# ---------------------------------------------------------------
#  5. Install packages
# ---------------------------------------------------------------
log "[1/7] Installing official packages..."
sudo pacman -S --needed --noconfirm "${OFFICIAL_PKGS[@]}"

log "[2/7] Installing AUR packages..."
$AUR_HELPER -S --needed --noconfirm "${AUR_PKGS[@]}"

# ---------------------------------------------------------------
#  6. Copy configs
# ---------------------------------------------------------------
copy_to() { # $1=src  $2=dst
    echo "  -> $2"
    mkdir -p "$DEST/$2"
    cp -r "$SCRIPT_DIR/$1/." "$DEST/$2/"
}

log "[3/7] Copying configs to $DEST"
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
copy_to obs-studio     obs-studio
copy_to nvim           nvim

chmod +x "$DEST"/scripts/*.sh 2>/dev/null || true

# ---------------------------------------------------------------
#  7. User services
# ---------------------------------------------------------------
log "[4/7] Enabling user services..."
systemctl --user daemon-reload
systemctl --user enable --now graphical-session.target 2>/dev/null || true
systemctl --user enable --now swayosd-server.service 2>/dev/null || true

# swayosd needs write access to /sys/class/backlight/*/brightness,
# which is group-writable by the 'video' group (see 99-swayosd.rules).
if ! id -nG | tr ' ' '\n' | grep -qx video; then
    sudo usermod -aG video "$USER"
    warn "  added $USER to the 'video' group — re-login for brightness keys to work"
fi

# ---------------------------------------------------------------
#  8. System services (NetworkManager / bluetooth / iwd)
# ---------------------------------------------------------------
log "[5/7] Enabling system services..."
sudo systemctl enable --now NetworkManager 2>/dev/null || true
sudo systemctl enable --now bluetooth 2>/dev/null || true
[[ -d /etc/NetworkManager/conf.d ]] && \
    printf '[device]\nwifi.backend=iwd\n' | sudo tee /etc/NetworkManager/conf.d/wifi-backend.conf >/dev/null

# ---------------------------------------------------------------
#  9. SDDM (theme + config + sudoers for wallpaper sync)
# ---------------------------------------------------------------
log "[6/7] Setting up SDDM..."

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
#  10. Misc: bashrc, user dirs, default wallpaper
# ---------------------------------------------------------------
log "[7/7] Installing bashrc, user directories, wallpaper..."

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

# Default wallpaper shipped with the repo so the user has one on first boot.
# It's only applied if no wallpaper has been set yet — after that, their own
# collection in ~/Pictures/Wallpapers/ takes over.
mkdir -p "$HOME/Pictures/Wallpapers"
DEFAULT_WALL="$SCRIPT_DIR/wallpapers/monstera.png"
CACHE_FILE="$DEST/scripts/.current_wallpaper"
if [[ -f "$DEFAULT_WALL" ]]; then
    if [[ -f "$CACHE_FILE" ]] && [[ -f "$(cat "$CACHE_FILE")" ]]; then
        warn "  wallpaper already set — leaving ~/Pictures/Wallpapers untouched"
    else
        if [[ ! -f "$HOME/Pictures/Wallpapers/monstera.png" ]]; then
            cp "$DEFAULT_WALL" "$HOME/Pictures/Wallpapers/monstera.png"
            log "  copied default wallpaper to ~/Pictures/Wallpapers/monstera.png"
        fi
        echo "$HOME/Pictures/Wallpapers/monstera.png" > "$CACHE_FILE"
        log "  default wallpaper staged — it will apply on first Hyprland start"
    fi
else
    warn "  no bundled wallpaper found — run wallpaper.sh init after first boot"
fi

# ---------------------------------------------------------------
#  11. Done
# ---------------------------------------------------------------
cat <<EOF

${GRN}Installation complete!${RST}

Next steps:
  1. Reload the shell (source ~/.bashrc) — aliases + eza icons + prompt from repo's bashrc
  2. Log out, switch to sddm, log back in
  3. A default wallpaper (monstera.png) is already staged — it applies on
     first Hyprland start. Drop your own images into ~/Pictures/Wallpapers/
     and use SUPER+W (random) / SUPER+SHIFT+W (picker) to switch.
  4. User directories are ready: ~/Downloads ~/Documents ~/Music ~/Pictures
     ~/Videos ~/Projects (folder icons show in file managers and terminal via eza)

Notes:
  * Requires Hyprland >= 0.55 (config uses the Lua API)
  * Recolor everything after a wallpaper change: run wallpaper.sh
    (SUPER+W random, SUPER+SHIFT+W picker)
  * SDDM theme will mirror your current wallpaper automatically
    (matugen post_hook runs sddm-sync.sh via the sudoers rule above)
  * Both paru and yay are installed; use whichever you prefer.
EOF
