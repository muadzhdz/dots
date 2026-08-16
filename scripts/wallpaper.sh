#!/usr/bin/env bash
set -euo pipefail
shopt -s inherit_errexit nullglob

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
CACHE_FILE="$HOME/.config/scripts/.current_wallpaper"
TRANSITION_DURATION=1.5
TRANSITION_FPS=60

ensure_daemon() {
    if ! pgrep -x awww-daemon >/dev/null 2>&1; then
        awww-daemon &
        sleep 0.5
    fi
}

set_wallpaper() {
    local img="$1"

    if [[ ! -f "$img" ]]; then
        echo "Image not found: $img"
        exit 1
    fi

    awww img \
        --transition-type random \
        --transition-duration "$TRANSITION_DURATION" \
        --transition-fps "$TRANSITION_FPS" \
        "$img"

    echo "$img" > "$CACHE_FILE"

    matugen image "$img" -q --config "$HOME/.config/matugen/matugen.toml" --prefer darkness >/dev/null 2>&1 || true

    # Waybar is never touched here — it stays completely still while the
    # wallpaper changes (no reload, no recolor). The new matugen waybar.css
    # is picked up the next time the bar is (re)started via waybar-hide.sh.
}

cmd_init() {
    ensure_daemon
    if [[ -f "$CACHE_FILE" ]]; then
        local cached
        cached=$(cat "$CACHE_FILE")
        if [[ -f "$cached" ]]; then
            set_wallpaper "$cached"
            return
        fi
    fi
    cmd_random
}

cmd_next() {
    local -a images=()
    while IFS= read -r -d '' f; do
        images+=("$f")
    done < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.bmp' -o -iname '*.webp' \) -print0 | sort -z)

    if ((${#images[@]} == 0)); then
        echo "No wallpapers found"
        exit 1
    fi

    local current=""
    [[ -f "$CACHE_FILE" ]] && current=$(cat "$CACHE_FILE")

    local idx=-1
    for i in "${!images[@]}"; do
        if [[ "${images[$i]}" == "$current" ]]; then
            idx=$i
            break
        fi
    done

    local next_idx=$(( (idx + 1) % ${#images[@]} ))
    if ((next_idx == 0 && idx == -1)); then
        next_idx=$((RANDOM % ${#images[@]}))
    fi

    set_wallpaper "${images[$next_idx]}"
}

cmd_prev() {
    local -a images=()
    while IFS= read -r -d '' f; do
        images+=("$f")
    done < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.bmp' -o -iname '*.webp' \) -print0 | sort -z)

    if ((${#images[@]} == 0)); then
        echo "No wallpapers found"
        exit 1
    fi

    local current=""
    [[ -f "$CACHE_FILE" ]] && current=$(cat "$CACHE_FILE")

    local idx=-1
    for i in "${!images[@]}"; do
        if [[ "${images[$i]}" == "$current" ]]; then
            idx=$i
            break
        fi
    done

    local prev_idx=$(( idx <= 0 ? ${#images[@]} - 1 : idx - 1 ))
    if ((idx == -1)); then
        prev_idx=$((RANDOM % ${#images[@]}))
    fi

    set_wallpaper "${images[$prev_idx]}"
}

cmd_random() {
    local -a images=()
    while IFS= read -r -d '' f; do
        images+=("$f")
    done < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.bmp' -o -iname '*.webp' \) -print0 | sort -z)

    if ((${#images[@]} == 0)); then
        echo "No wallpapers found"
        exit 1
    fi

    local idx=$((RANDOM % ${#images[@]}))
    set_wallpaper "${images[$idx]}"
}

cmd_set() {
    if [[ -z "${1-}" ]]; then
        echo "Usage: wallpaper.sh set <path>"
        exit 1
    fi
    set_wallpaper "$1"
}

ensure_daemon

case "${1-}" in
    init)   cmd_init ;;
    next)   cmd_next ;;
    prev)   cmd_prev ;;
    random) cmd_random ;;
    set)    shift; cmd_set "$@" ;;
    *)
        echo "Usage: wallpaper.sh {init|next|prev|random|set <path>}"
        exit 1
        ;;
esac
