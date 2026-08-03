#!/bin/bash
# Convert hex_stripped to Chromium/Helium RGB array format: [r, g, b]
hex_to_rgb() {
    local h=$1
    local r=$((16#${h:0:2}))
    local g=$((16#${h:2:2}))
    local b=$((16#${h:4:2}))
    echo "[$r, $g, $b]"
}

# Read colors from generated file
COLOR_FILE="$HOME/.config/matugen/generated/chromium-colors.conf"
if [ ! -f "$COLOR_FILE" ]; then
    exit 0
fi

source "$COLOR_FILE"

# Generate Chromium manifest
CHROMIUM_DIR="$HOME/.config/chromium/Default/Extensions/matugen-theme"
mkdir -p "$CHROMIUM_DIR"
cat > "$CHROMIUM_DIR/manifest.json" << EOF
{
  "manifest_version": 3,
  "name": "Matugen Theme",
  "version": "1.0",
  "description": "Auto-generated theme from matugen",
  "theme": {
    "colors": {
      "frame": $(hex_to_rgb "$surface"),
      "toolbar": $(hex_to_rgb "$surface_dim"),
      "tab_text": $(hex_to_rgb "$on_surface"),
      "tab_background_text": $(hex_to_rgb "$on_surface_variant"),
      "bookmark_text": $(hex_to_rgb "$on_surface"),
      "ntp_background": $(hex_to_rgb "$surface"),
      "ntp_text": $(hex_to_rgb "$on_surface"),
      "ntp_link": $(hex_to_rgb "$primary"),
      "ntp_section": $(hex_to_rgb "$surface_container"),
      "omnibox_text": $(hex_to_rgb "$on_surface"),
      "omnibox_background": $(hex_to_rgb "$surface_container"),
      "tab_background_color": $(hex_to_rgb "$surface_dim"),
      "tab_foreground_color": $(hex_to_rgb "$on_surface"),
      "toolbar_button_icon_color": $(hex_to_rgb "$on_surface_variant"),
      "button_background_hover": $(hex_to_rgb "$primary_container"),
      "button_background_pressed": $(hex_to_rgb "$primary")
    },
    "properties": {
      "ntp_logo_alternate": 0
    }
  }
}
EOF

# Generate Helium manifest (same format)
HELIUM_DIR="$HOME/.config/helium/Default/Extensions/matugen-theme"
mkdir -p "$HELIUM_DIR"
cp "$CHROMIUM_DIR/manifest.json" "$HELIUM_DIR/manifest.json"

echo "Browser themes generated"
