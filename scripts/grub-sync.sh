#!/usr/bin/env bash
set -euo pipefail

# GRUB theme sync: matugen material-you colors + current wallpaper
# Run as root (via sudoers NOPASSWD rule), called by matugen post_hook.
# Manual: sudo -n $HOME/.config/scripts/grub-sync.sh

REAL_USER="${SUDO_USER:-$USER}"
HOME_DIR="$(getent passwd "$REAL_USER" | cut -d: -f6)"
CACHE="$HOME_DIR/.config/scripts/.current_wallpaper"
VARS="$HOME_DIR/.cache/matugen/grub-vars.sh"
GEN_THEME="$HOME_DIR/.config/matugen/generated/grub-theme.txt"
DEST=/boot/grub/themes/matugen
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

W=1920
H=1080
PANEL_W=480
RADIUS=10
ENTRY_H=55
PAD=20
MAX_ENTRIES=8
FONT_SRC=/usr/share/fonts/TTF/JetBrainsMonoNerdFontMono-Regular.ttf
FONT_FALLBACK=/usr/share/fonts/TTF/DejaVuSans.ttf

log() { echo "grub-sync: $*"; }

[[ -f "$CACHE" ]] || { log "no wallpaper cache"; exit 0; }
WALL="$(cat "$CACHE")"
[[ -f "$WALL" ]] || { log "wallpaper missing: $WALL"; exit 0; }
[[ -f "$GEN_THEME" ]] || { log "generated theme missing (run matugen first)"; exit 0; }

[[ -f "$VARS" ]] && . "$VARS"
PRIMARY="${GRUB_PRIMARY:-7aa2f7}"
ON_PRIMARY="${GRUB_ON_PRIMARY:-ffffff}"
ON_SURFACE="${GRUB_ON_SURFACE:-eff0f1}"
SURFACE_CONTAINER="${GRUB_SURFACE_CONTAINER:-31363b}"

mkdir -p "$DEST"

# ---------------------------------------------------------------
#  1. /etc/default/grub: theme, gfxmode, os-prober (with backup)
# ---------------------------------------------------------------
GRUB_CONF=/etc/default/grub
cp -a "$GRUB_CONF" "$GRUB_CONF.bak"
apply_opt() {
    local key="$1" val="$2"
    if grep -q "^#\?${key}=" "$GRUB_CONF"; then
        sed -i "s|^#\?${key}=.*|${key}=${val}|" "$GRUB_CONF"
    else
        echo "${key}=${val}" >> "$GRUB_CONF"
    fi
}
apply_opt GRUB_THEME "$DEST/theme.txt"
apply_opt GRUB_GFXMODE "$W,$H,auto"
apply_opt GRUB_DISABLE_OS_PROBER false

# ---------------------------------------------------------------
#  2. grub-mkconfig -> temp, then inject OS icons into labels
# ---------------------------------------------------------------
grub-mkconfig -o "$TMP/grub.cfg" >/dev/null 2>&1 || { log "grub-mkconfig failed"; exit 1; }

ENTRIES="$(python3 - "$TMP/grub.cfg" "$TMP/grub.cfg.out" <<'PYEOF'
import re, sys

MAP = [
    (("windows",),                           0xF17A),
    (("mac", "apple", "darwin"),             0xF179),
    (("android",),                           0xF17B),
    (("artix",),                             0xF31F),
    (("endeavour",),                         0xF322),
    (("cachyos",),                           0xF385),
    (("garuda",),                            0xF337),
    (("nobara",),                            0xF380),
    (("manjaro",),                           0xF312),
    (("archcraft",),                         0xF345),
    (("arcolinux",),                         0xF346),
    (("ubuntu", "kubuntu", "xubuntu", "lubuntu"), 0xF31B),
    (("debian",),                            0xF306),
    (("fedora",),                            0xF30A),
    (("mint",),                              0xF30E),
    (("pop",),                               0xF32A),
    (("kali",),                              0xF327),
    (("nixos",),                             0xF313),
    (("opensuse", "suse"),                   0xF314),
    (("tumbleweed",),                        0xF37D),
    (("leap",),                              0xF37E),
    (("gentoo",),                            0xF30D),
    (("void",),                              0xF32E),
    (("solus",),                             0xF32D),
    (("zorin",),                             0xF32F),
    (("deepin",),                            0xF321),
    (("rocky",),                             0xF32B),
    (("almalinux",),                         0xF31D),
    (("red hat", "rhel"),                    0xF316),
    (("slackware",),                         0xF318),
    (("tails",),                             0xF343),
    (("raspbian", "raspberry"),              0xF315),
    (("freebsd",),                           0xF28F),
    (("openbsd",),                           0xF328),
    (("parrot",),                            0xF329),
    (("mx",),                                0xF33F),
    (("arch",),                              0xF303),
    (("uefi", "firmware", "bios", "setup"),  None),
]
FALLBACK = 0xF17C

def icon_for(label):
    low = label.lower()
    for kws, cp in MAP:
        if any(k in low for k in kws):
            return "" if cp is None else (chr(cp) + " ")
    return chr(FALLBACK) + " "

def clean(label):
    label = re.sub(r"\s*\(on\s+[^)]*\)\s*$", "", label)
    label = re.sub(r"^\s*[\ue000-\uf8ff]\s*", "", label)  # drop previous icon
    return label.strip()

src, out = sys.argv[1], sys.argv[2]
text = open(src, encoding="utf-8").read()
def repl(m):
    head, label = m.group(1), m.group(2)
    return head + icon_for(label) + clean(label) + "'"

text = re.sub(r"((?:menuentry|submenu)\s+')([^']*)'", repl, text)
with open(out, "w", encoding="utf-8") as f:
    f.write(text)
count = sum(1 for ln in text.splitlines() if re.match(r"^\s*(menuentry|submenu)\s+", ln))
print(count)
PYEOF
)"

[[ "$ENTRIES" =~ ^[0-9]+$ ]] || ENTRIES=1
n=$ENTRIES
[[ $n -lt 4 ]] && n=4
[[ $n -gt $MAX_ENTRIES ]] && n=$MAX_ENTRIES

# ---------------------------------------------------------------
#  3. Background: heavy blur + dim (special-workspace vibes)
# ---------------------------------------------------------------
ffmpeg -y -loglevel error -i "$WALL" \
    -vf "scale=$W:$H:force_original_aspect_ratio=increase,crop=$W:$H,gblur=sigma=30,eq=brightness=0.55:saturation=1.0" \
    -frames:v 1 "$TMP/base.png"

# ---------------------------------------------------------------
#  4. Rofi-like panel: rounded rect, centered, 25% width
# ---------------------------------------------------------------
PANEL_H=$((n * ENTRY_H + 2 * PAD))
TOP_PX=$(( (H - PANEL_H) / 2 ))
X1=$(( (W - PANEL_W) / 2 + 1 ))
Y1=$((TOP_PX + 1))
X2=$((X1 + PANEL_W - 2))
Y2=$((TOP_PX + PANEL_H - 1))

magick "$TMP/base.png" \
    -fill 'rgba(0,0,0,0.40)' -stroke "#$PRIMARY" -strokewidth 2 \
    -draw "roundrectangle $X1,$Y1 $X2,$Y2 $RADIUS,$RADIUS" \
    "$DEST/background.png"

MENU_LEFT_PCT=38.5
MENU_WIDTH_PCT=23.0
MENU_TOP_PCT=$(awk "BEGIN{printf \"%.1f\", ($TOP_PX+8)*100/$H}")
MENU_HEIGHT_PCT=$(awk "BEGIN{printf \"%.1f\", ($PANEL_H-16)*100/$H}")

# ---------------------------------------------------------------
#  5. 9-slice pixmaps: selection highlight + progress bar
# ---------------------------------------------------------------
gen_solid() { # name color
    magick -size 20x21 "xc:#$2" "$DEST/$1"
}
gen_corner() { # name cx cy  (punch quarter circle at outer corner)
    local mask="$TMP/mask-$1.png"
    magick -size 20x21 xc:white -fill black -draw "circle $2,$3 $2,$((3+10))" "$mask"
    magick -size 20x21 "xc:#$PRIMARY" "$mask" -alpha off -compose CopyOpacity -composite "$DEST/$1"
}

gen_corner select_nw.png 0 0
gen_corner select_ne.png 19 0
gen_corner select_sw.png 0 20
gen_corner select_se.png 19 20
for s in c n s e w; do gen_solid "select_$s.png" "$PRIMARY"; done

gen_solid progress_bar_c.png "$SURFACE_CONTAINER"
gen_solid progress_highlight_c.png "$PRIMARY"

# ---------------------------------------------------------------
#  6. Fonts (cached): Nerd Font -> pf2 (icons + text)
# ---------------------------------------------------------------
if [[ -f "$FONT_SRC" ]]; then
    FONT="$FONT_SRC"
    FNAME="JetBrains Mono Regular"
else
    FONT="$FONT_FALLBACK"
    FNAME="DejaVu Sans Regular"
fi
[[ -f "$DEST/$FNAME-24.pf2" ]] || grub-mkfont -s 24 -n "$FNAME" -o "$DEST/$FNAME-24.pf2" "$FONT"
[[ -f "$DEST/$FNAME-16.pf2" ]] || grub-mkfont -s 16 -n "$FNAME" -o "$DEST/$FNAME-16.pf2" "$FONT"

# ---------------------------------------------------------------
#  7. theme.txt: render + geometry
# ---------------------------------------------------------------
sed -e "s|__MENU_LEFT_PCT__|$MENU_LEFT_PCT|" \
    -e "s|__MENU_WIDTH_PCT__|$MENU_WIDTH_PCT|" \
    -e "s|__MENU_TOP_PCT__|$MENU_TOP_PCT|" \
    -e "s|__MENU_HEIGHT_PCT__|$MENU_HEIGHT_PCT|" \
    -e "s|JetBrains Mono Regular|$FNAME|g" \
    "$GEN_THEME" > "$DEST/theme.txt"

# ---------------------------------------------------------------
#  8. Install grub.cfg with icons
# ---------------------------------------------------------------
cp -f "$TMP/grub.cfg.out" /boot/grub/grub.cfg

log "done: $DEST ($ENTRIES entries, top=$MENU_TOP_PCT% height=$MENU_HEIGHT_PCT%)"
