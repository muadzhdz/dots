# dots

Personal Hyprland dotfiles based on [Omarchy](https://github.com/basecamp/omarchy) & [Dusky](https://github.com/dusklinux/dusky), with full Material You theming via [matugen](https://github.com/InioX/matugen).

Every component (waybar, kitty, rofi, mako, swayosd, btop, cava, ghostty, GTK, browser themes) recolors itself automatically on every wallpaper change. Config uses the **Lua API** (requires Hyprland >= 0.55).

## Components

Hyprland, waybar, mako, rofi (wayland), kitty, ghostty, hyprlock, matugen, awww, swayosd, cliphist, grim/slurp/satty, dolphin.

## Install

```bash
git clone https://github.com/muadzhdz/dots && cd dots
./install.sh
```

Then put wallpapers in `~/Pictures/Wallpapers/`, restart Hyprland, and run:

```bash
~/.config/scripts/wallpaper.sh init
```

`matugen/generated/` is committed so colors work even before running matugen.

> **swayosd:** this setup expects the custom **24px-icon build**. The stock package ships 32px icons — rebuild from `config.toml`/`style.css` or expect oversized icons.

## Keybinds

| Key | Action |
|---|---|
| `SUPER + Return` | terminal |
| `SUPER + Space` | launcher |
| `SUPER + ALT + Space` | power menu |
| `SUPER + E` | file manager |
| `SUPER + Q` | close window |
| `SUPER + F` / `+ SHIFT + F` | fullscreen / maximized |
| `SUPER + T` | toggle float |
| `SUPER + W` / `+ SHIFT + W` | random wallpaper / picker |
| `SUPER + V` | clipboard history |
| `SUPER + S` | scratchpad |
| `SUPER + L` | lock |
| `SUPER + M` | shutdown |
| `Print` / `SUPER + SHIFT + S` | screenshot |
| `SUPER + Print` | OCR |
| `SUPER + ALT + E` | emoji picker |
| `ALT + Tab` / `SHIFT` | cycle windows |
| `SUPER + arrows` / `+ SHIFT` | focus / swap |
| `SUPER + 1-0` / `+ SHIFT` | workspace / move |

## Credits

- [Omarchy](https://github.com/basecamp/omarchy) by DHH (MIT)
- [Dusky](https://github.com/dusklinux/dusky) by dusklinux (MIT)
- [MatugenFox](https://github.com/Ubaidullah-Web-Dev/MatugenFox) — browser theming

## License

[MIT](LICENSE)
