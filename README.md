# dots

Personal Hyprland dotfiles based on [Omarchy](https://github.com/basecamp/omarchy) & [Dusky](https://github.com/dusklinux/dusky), with full Material You theming via [matugen](https://github.com/InioX/matugen).

Every component (waybar, kitty, rofi, mako, swayosd, btop, cava, ghostty, GTK, browser themes) recolors itself automatically on every wallpaper change. Config uses the **Lua API** (requires Hyprland >= 0.55).

## Features

- **Material You theming** — one wallpaper drives every app color via matugen (waybar, kitty, ghostty, rofi, mako, swayosd, btop, cava, GTK3/4, hyprlock, hyprland borders, SDDM login screen)
- **Moveable waybar** — the bar lives on all four screen edges: top/bottom bars are horizontal, left/right are vertical (rotated). Workspace transitions (slide vs slidevert) and the 3-finger swipe gesture follow the bar's orientation. On switch, the old bar fades out and the new one slides in from its own edge. `SUPER + ALT + W` cycles, `SUPER + ALT + SHIFT + W` opens a position menu.
- **Default browser switcher** (`SUPER + ALT + B`) — rofi menu that lists every installed browser and sets the system default via `xdg-settings`/`xdg-mime` (supports firefox, chromium, zen, helium, brave, chrome)
- **Web apps manager** (`SUPER + SHIFT + A`) — `webapp-installer.sh` generates `.desktop` entries for sites you want as standalone apps
- **Wallpaper daemon** — `awww` with animated crossfade transitions
- **hypridle** — auto lock after 10 min, DPMS off after 10:30
- **Keybinds menu** (`SUPER + K`) — interactive rofi list generated straight from `binds.lua`, with executable actions
- **Display menu** (`SUPER + D`) — pick a monitor, mode and scale via rofi; last selection is remembered across restarts
- **SDDM mirror** — the login screen shows your current wallpaper (via `sddm-sync.sh`, auto-run by matugen)
- **Polkit agent** — polkit-kde-agent autostarted

## Components

Hyprland, waybar, mako, rofi (wayland), kitty, ghostty, hyprlock, hypridle, matugen, awww, swayosd, cliphist, grim/slurp/satty, hyprpicker, nautilus, bluetui, wiremix, impala, neovim, obs-studio.

## Install

Requires an **Arch-based** distro with sudo. Installer installs all dependencies (official + AUR), copies configs, enables services, and sets up SDDM.

```bash
git clone https://github.com/muadzhdz/dots && cd dots
./install.sh
```

Then:

1. Reload your shell (`source ~/.bashrc`) — your aliases + prompt come from the repo's `bashrc` (the installer backs up an existing `~/.bashrc` to `~/.bashrc.bak` first)
2. Log out, log in from the SDDM screen
3. A bundled wallpaper (`wallpapers/monstera.png`) is staged as the default — it applies on first Hyprland start. Drop your own images into `~/Pictures/Wallpapers/` and use `SUPER + W` (random) / `SUPER + SHIFT + W` (picker) to switch.

`matugen/generated/` is committed so colors work even before running matugen.

> **swayosd:** icon size is forced to 24px via `templates/swayosd.css`/`style.css`, so the stock package is fine — no custom build needed.

## Dependencies

Installed automatically by `install.sh`. The installer sets up **both** `paru` and `yay` (AUR helpers), then asks which browser(s) you want: chromium, firefox, zen-browser, helium-browser, tor-browser (pick one or several, or all).

**Official (pacman):** hyprland, hypridle, hyprlock, waybar, mako, rofi, kitty, ghostty, cliphist, grim, slurp, satty, hyprpicker, tesseract, tesseract-data-eng, jq, playerctl, pamixer, btop, cava, qt6ct, bluez, bluez-utils, networkmanager, iwd, sddm, polkit-kde-agent, bluetui, wiremix, impala, matugen, swayosd, awww, libnotify, bc, brightnessctl, nautilus, obs-studio, neovim, xdg-desktop-portal-hyprland, cmatrix, tree, chafa, mpv, imv, gnome-disk-utility, wl-clipboard, wireplumber, pipewire-pulse, ttf-jetbrains-mono-nerd, noto-fonts, ttf-dejavu, adw-gtk-theme, papirus-icon-theme, kvantum, eza, xdg-user-dirs, fastfetch, zip, unzip, chromium, firefox

**AUR:** sddm-silent-theme, ttf-material-symbols-variable-git, redhat-fonts, yaru-gtk-theme, zen-browser-bin, helium-browser-bin, tor-browser-bin, visual-studio-code-bin

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
| `SUPER + ALT + W` / `+ SHIFT + W` | cycle waybar position / position menu |
| `SUPER + SHIFT + SPACE` | toggle waybar visibility |
| `SUPER + V` | clipboard history |
| `SUPER + S` / `+ SHIFT + V` | scratchpad / move to scratchpad |
| `SUPER + L` | lock (hyprlock) |
| `SUPER + M` | exit session |
| `SUPER + ALT + B` | default browser switcher |
| `SUPER + SHIFT + A` | web apps manager |
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

## Waybar

Managed by `scripts/waybar-position.sh` (called with `init` from `hypr/modules/autostart.lua`). It supports `init`, `cycle`, `menu`, or a direct position: `top` / `bottom` / `left` / `right`.

What changes on each position:

- **Waybar config** — top/bottom: 1000×37 horizontal bar; left/right: 37×1000 vertical bar (clock rotated 270°). Current position is cached in `~/.config/waybar/.current_position`
- **Workspace transitions** — top/bottom use horizontal `slide`; left/right use vertical `slidevert`. The special (scratchpad) workspace always slides in the opposite axis
- **3-finger swipe gesture** — horizontal swipe when the bar is at top/bottom, vertical swipe when it's at left/right
- **Rofi** — keeps its directional entrance: when the waybar is on the left, rofi slides in from the right, and vice versa (per-layer rule, so mako/swayosd are unaffected)
- **Bar transition** — switching positions kills the old bar (it fades out via `layersOut` = fade) and the new bar slides in from its own edge (`layersIn` = slide), so there's no cross-screen travel

The waybar background is `alpha(@surface-container, 0.75)` from the matugen palette, so it recolors with every wallpaper change (template: `matugen/templates/waybar.css`, recoloring is handled by `wallpaper.sh`, which restarts the bar through `scripts/waybar-hide.sh apply`).

## Waybar hide/show

`scripts/waybar-hide.sh {toggle|hide|show|apply}` — `SUPER+SHIFT+SPACE` toggles:

- **hide** — writes `~/.config/waybar/.hidden` and sends `SIGUSR1` (mapped to `"hide"` in the waybar config; an idempotent *set*, so no state drift). The bar process stays alive.
- **show** — removes the marker and restarts the bar (`waybar &`), which comes up visible.
- **apply** — restarts the bar **only if it isn't hidden** (restart points: wallpaper change, border mode, bar position). A hidden bar is never restarted, so it can never pop back up.
- Wallpaper changes skip the waybar restart entirely while hidden — the new matugen style is picked up on the next `show`.

`matugen` has **no** waybar post_hook (a `SIGUSR2` reload would unhide the bar); recoloring is done by `wallpaper.sh` only.

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
