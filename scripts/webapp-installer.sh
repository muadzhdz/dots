#!/usr/bin/env bash
set -euo pipefail

# Web App Installer for Hyprland + Rofi + Chromium
# Generates native-like standalone window web apps

ROFI_CMD="rofi -dmenu -i -p"
ICON_DIR="$HOME/.local/share/icons"
DESKTOP_DIR="$HOME/.local/share/applications"

mkdir -p "$ICON_DIR" "$DESKTOP_DIR"

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -i "$1" "$2" "$3"
    fi
}

rofi_prompt() {
    local prompt="$1"
    echo "" | $ROFI_CMD "$prompt"
}

action=$(printf "󰐕  Install New Web App\n󰩹  Remove Web App" | $ROFI_CMD "Web Apps:")

[[ -z "$action" ]] && exit 0

if [[ "$action" == *"Install"* ]]; then
    # Step 1: App Name
    app_name=$(rofi_prompt "App Name:")
    [[ -z "$app_name" ]] && exit 0

    # Sanitize name for filenames
    safe_name=$(echo "$app_name" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_-')

    # Step 2: URL
    app_url=$(rofi_prompt "App URL:")
    [[ -z "$app_url" ]] && exit 0

    # Ensure http:// or https:// prefix
    if [[ ! "$app_url" =~ ^https?:// ]]; then
        app_url="https://$app_url"
    fi

    # Extract domain for favicon lookup
    domain=$(echo "$app_url" | awk -F/ '{print $3}')

    # Step 3: Icon URL (Optional)
    icon_url=$(rofi_prompt "Custom Icon URL:")

    icon_path="$ICON_DIR/webapp-$safe_name.png"

    if [[ -n "$icon_url" ]]; then
        curl -sL "$icon_url" -o "$icon_path" || true
    fi

    # Fallback to Google Favicon API if icon download failed or skipped
    if [[ ! -f "$icon_path" ]] || [[ ! -s "$icon_path" ]]; then
        curl -sL "https://www.google.com/s2/favicons?domain=${domain}&sz=256" -o "$icon_path" || true
    fi

    # Generate .desktop file
    desktop_file="$DESKTOP_DIR/webapp-$safe_name.desktop"

    cat << EOF > "$desktop_file"
[Desktop Entry]
Version=1.0
Type=Application
Name=$app_name
Comment=Web Application for $app_name
Exec=chromium --app=$app_url --name=$safe_name --class=webapp-$safe_name
Icon=$icon_path
Terminal=false
StartupNotify=true
Categories=Network;WebApplication;
StartupWMClass=webapp-$safe_name
EOF

    chmod +x "$desktop_file"

    # Update desktop database if available
    command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true

    notify "web-browser" "Web App Installed" "'$app_name' is now available in your App Launcher."

elif [[ "$action" == *"Remove"* ]]; then
    # List installed web apps
    installed_apps=$(find "$DESKTOP_DIR" -name "webapp-*.desktop" 2>/dev/null)

    if [[ -z "$installed_apps" ]]; then
        notify "dialog-warning" "No Web Apps Found" "No installed web apps found to remove."
        exit 0
    fi

    list=""
    while IFS= read -r file; do
        name=$(grep "^Name=" "$file" | cut -d'=' -f2)
        list+="󰩹  $name | $(basename "$file")\n"
    done <<< "$installed_apps"

    selected=$(echo -e "$list" | $ROFI_CMD "Select Web App:")
    [[ -z "$selected" ]] && exit 0

    file_to_remove=$(echo "$selected" | awk -F'| ' '{print $2}')
    if [[ -n "$file_to_remove" ]] && [[ -f "$DESKTOP_DIR/$file_to_remove" ]]; then
        rm -f "$DESKTOP_DIR/$file_to_remove"
        notify "user-trash" "Web App Removed" "Removed $selected"
    fi
fi
