# dots

Personal Hyprland dotfiles based on [Omarchy](https://github.com/basecamp/omarchy) & [Dusky](https://github.com/dusklinux/dusky), with full Material You theming via [matugen](https://github.com/InioX/matugen).

Every component (waybar, kitty, rofi, mako, swayosd, btop, cava, ghostty, GTK, browser themes) recolors itself automatically on every wallpaper change. Config uses the **Lua API** (requires Hyprland >= 0.55).

## Features

- **Material You theming** — one wallpaper drives every app color via matugen (waybar, kitty, ghostty, rofi, mako, swayosd, btop, cava, GTK3/4, hyprlock, hyprland borders, SDDM login screen)
- **Wallpaper daemon** — `awww` with animated crossfade transitions
- **hypridle** — auto lock after 10 min, DPMS off after 10:30
- **Keybinds menu** (`SUPER + K`) — interactive rofi list generated straight from `binds.lua`, with executable actions
- **Display menu** (`SUPER + D`) — pick a monitor, mode and scale via rofi; last selection is remembered across restarts
- **SDDM mirror** — the login screen shows your current wallpaper (via `sddm-sync.sh`, auto-run by matugen)
- **Polkit agent** — polkit-kde-agent autostarted

## Components

Hyprland, waybar, mako, rofi (wayland), kitty, ghostty, hyprlock, hypridle, matugen, awww, swayosd, cliphist, grim/slurp/satty, nautilus, bluetui, wiremix, impala.

## Install

Requires an **Arch-based** distro with sudo. Installer installs all dependencies (official + AUR), copies configs, enables services, and sets up SDDM.

```bash
git clone https://github.com/muadzhdz/dots && cd dots
./install.sh
```

Then:

1. Put wallpapers in `~/Pictures/Wallpapers/`
2. Reload your shell (`source ~/.bashrc`) for the long-format `ls` alias
3. Log out, log in from the SDDM screen
4. First time, run: `~/.config/scripts/wallpaper.sh init`

`matugen/generated/` is committed so colors work even before running matugen.

> **swayosd:** icon size is forced to 24px via `templates/swayosd.css`/`style.css`, so the stock package is fine — no custom build needed.

## Dependencies

Installed automatically by `install.sh`. The AUR packages need a helper (`paru`/`yay`) — the installer bootsraps `paru` if you don't have one.

**Official (pacman):** hyprland, hypridle, hyprlock, waybar, mako, rofi, kitty, ghostty, cliphist, grim, slurp, satty, jq, playerctl, pamixer, btop, cava, qt6ct, bluez, bluez-utils, networkmanager, iwd, sddm, polkit-kde-agent, bluetui, wiremix, impala, matugen, swayosd

**AUR:** sddm-silent-theme, ttf-material-symbols-variable-git, redhat-fonts, yaru-gtk-theme, adw-gtk3

## Keybinds

| Key | Action |
|---|---|
| `SUPER + Return` | terminal |
| `SUPER + Space` | app launcher |
| `SUPER + K` | show keybinds menu |
| `SUPER + ALT + Space` | power menu |
| `SUPER + D` | display settings (monitor / mode / scale) |
| `SUPER + E` | file manager (nautilus) |
| `SUPER + Q` | close window |
| `SUPER + F` / `+ SHIFT + F` | fullscreen / maximized |
| `SUPER + T` / `+ P` | toggle float / pseudo-tile |
| `SUPER + J` | toggle split layout |
| `SUPER + W` / `+ SHIFT + W` | random wallpaper / picker |
| `SUPER + V` | clipboard history |
| `SUPER + S` / `+ SHIFT + V` | scratchpad / move to scratchpad |
| `SUPER + L` | lock (hyprlock) |
| `SUPER + M` | exit session |
| `Print` / `SUPER + SHIFT + S` | screenshot |
| `SUPER + Print` | OCR screenshot |
| `SUPER + ALT + E` | emoji picker |
| `SUPER + slash` / `+ ALT` | cycle display scale / reverse |
| `ALT + Tab` / `+ SHIFT` | cycle windows |
| `CTRL + ALT + Tab` / `+ SHIFT` | cycle monitors |
| `SUPER + arrows` / `+ SHIFT` | focus / swap windows |
| `SUPER + 1-0` / `+ SHIFT` | workspace / move to workspace |
| `SUPER + mouse_down` / `mouse_up` | next / previous workspace |
| `SUPER + LMB` / `RMB` | move / resize window |
| `XF86Audio*`, `XF86MonBrightness*` | volume / brightness (swayosd) |

## SDDM

- Theme: [`sddm-silent-theme`](https://github.com/manueljenni/sddm-silent-theme) (AUR)
- `install.sh` writes `/etc/sddm.conf.d/silent-theme.conf` and enables `sddm.service`
- The login screen mirrors your current wallpaper: matugen's `sddm` template renders a themed `default.conf`, then `sddm-sync.sh` copies the wallpaper + config into the theme dir. It runs as root via a passwordless sudoers rule (`/etc/sudoers.d/sddm-sync`) added for the installing user.
- Everything is portable — no hardcoded user paths; the script resolves your home via `$SUDO_USER`.

## Credits

- [Omarchy](https://github.com/basecamp/omarchy) by DHH (MIT)
- [Dusky](https://github.com/dusklinux/dusky) by dusklinux (MIT)
- [MatugenFox](https://github.com/Ubaidullah-Web-Dev/MatugenFox) — browser theming

## License

[MIT](LICENSE)
