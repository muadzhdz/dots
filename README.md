# hyprland-rice

A Hyprland dotfiles setup with full Material You theming via [matugen](https://github.com/InioX/matugen). Written in the **Lua config API** (requires Hyprland >= 0.55).

Every themeable component (waybar, kitty, rofi, mako, swayosd, btop, cava, ghostty, GTK, borders, lockscreen, browser themes) is recolored automatically every time the wallpaper changes.

## Components

| Component | Tool |
|---|---|
| WM / compositor | [Hyprland](https://hyprland.org) (Lua API) |
| Bar | [waybar](https://github.com/Alexays/Waybar) |
| Notifications | [mako](https://github.com/emersion/mako) |
| Launcher / menus / pickers | [rofi](https://github.com/lbonn/rofi) (wayland fork) |
| Terminal | [kitty](https://sw.kovidgoyal.net/kitty/) + [ghostty](https://ghostty.org) |
| Lock screen | [hyprlock](https://github.com/hyprwm/hyprlock) |
| Color engine | [matugen](https://github.com/InioX/matugen) + `python-materialyoucolor` |
| Wallpaper daemon | [awww](https://github.com/Baldomo/awww) + awww-daemon |
| OSD (volume/brightness) | [swayosd](https://github.com/ErikReider/SwayOSD) |
| Clipboard | [cliphist](https://github.com/sentriz/cliphist) + wl-clipboard |
| Screenshots / OCR | [grim](https://github.com/emersion/grim) + [slurp](https://github.com/emersion/slurp) + [satty](https://github.com/gabm/Satty) + tesseract |
| File manager | dolphin |
| Color picker | hyprpicker |

## Dependencies

Arch Linux (adjust for your distro):

```bash
# main
pacman -S hyprland hyprlock hyprpicker waybar mako rofi kitty dolphin \
          xdg-desktop-portal-hyprland swayosd matugen cliphist wl-clipboard \
          grim slurp satty tesseract jq bc libnotify playerctl pipewire wireplumber \
          ttf-jetbrains-mono-nerd noto-fonts-emoji

# AUR
yay -S hyprshutdown python-materialyoucolor yaru-icon-theme adw-gtk3

# optional / scripts
pamixer dusky-run impala wiremix bluetui kvantum btop cava
```

### swayosd (custom build)

This setup uses a **custom-built swayosd with 24px icons** (upstream ships 32px).
If you install the standard `swayosd` package the OSD icons will look too big.
Rebuild from the repo's `config.toml`/`style.css` or override with your own build.

## Install

```bash
git clone https://github.com/muadzhdz/hyprland-rice ~/hyprland-rice
cd ~/hyprland-rice
./install.sh
```

Then put wallpapers in `~/Pictures/Wallpapers/`, log out and back in, and run:

```bash
~/.config/scripts/wallpaper.sh init
```

`matugen/generated/` is committed so the setup works even before you change
wallpapers, but running `wallpaper.sh` is what generates the colors.

> The repo ships without wallpapers. Grab your own — every theme follows the
> current wallpaper's palette.

## Keybinds

| Key | Action |
|---|---|
| `SUPER + Return` | open terminal |
| `SUPER + Space` | app launcher |
| `SUPER + ALT + Space` | power menu |
| `SUPER + E` | file manager |
| `SUPER + Q` | close window |
| `SUPER + F` / `SUPER + SHIFT + F` | fullscreen / maximized |
| `SUPER + T` | toggle float |
| `SUPER + W` | random wallpaper |
| `SUPER + SHIFT + W` | wallpaper picker (rofi) |
| `SUPER + V` | clipboard history |
| `SUPER + S` | scratchpad (special workspace) |
| `SUPER + L` | lock |
| `SUPER + M` | shutdown menu |
| `Print` / `SUPER + SHIFT + S` | screenshot |
| `SUPER + Print` | OCR screenshot |
| `SUPER + ALT + E` | emoji picker |
| `SUPER + slash` | monitor scaling cycle |
| `ALT + Tab` / `ALT + SHIFT + Tab` | next / previous window |
| `CTRL + ALT + Tab` | next monitor |
| `SUPER + arrows` | focus |
| `SUPER + SHIFT + arrows` | swap windows |
| `SUPER + 1-0` | switch workspace |
| `SUPER + SHIFT + 1-0` | move window to workspace |
| `SUPER + mouse` | drag / resize |

## Notes

- `misc.on_focus_under_fullscreen = 1` is set in `hypr/modules/misc.lua` —
  windows you switch to become fullscreen (Windows-style Alt+Tab), instead of
  the default where leaving fullscreen undoes it.
- Alt+Tab, volume/brightness and media keys are defined in
  `hypr/modules/binds.lua`; tweak to taste.
- Browser theming (`scripts/generate-browser-themes.sh`) targets chromium,
  Firefox and Zen profiles; run it or let the matugen `chromium` post_hook
  handle it.
