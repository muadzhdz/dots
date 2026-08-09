#!/usr/bin/env bash
set -euo pipefail

N="${1:-5}"
CLASS="org.gnome.Nautilus"

sample_pixel() {
    local geom="$1"
    read -r gx gy gw gh <<< "$geom"
    local px=$((gx + 20)) py=$((gy + 20))
    local f="/tmp/opencode/naut-sample.png"
    grim -g "${px},${py} 1x1" "$f" 2>/dev/null || return 1
    local hex
    hex=$(ffmpeg -y -i "$f" -f rawvideo -pix_fmt rgb24 - 2>/dev/null | od -An -tx1 | tr -d ' \n')
    printf '#%s' "$hex"
}

nautilus_state() {
    hyprctl clients -j 2>/dev/null | jq -r --arg c "$CLASS" '.[] | select(.class==$c and .mapped==true) | "\(.address) \(.at[0]) \(.at[1]) \(.size[0]) \(.size[1]) \(.workspace.id)"' | head -1
}

printf '%-6s %-16s %-8s %-8s %-16s %-10s %-9s %-9s\n' "ITER" "PID" "POS" "SIZE" "COLOR" "CLOSE?" "PINDH?" "THEME?"
for i in $(seq 1 "$N"); do
    pid_b=$(pgrep -x nautilus | head -1)
    st_b=$(nautilus_state)
    col_b=$(sample_pixel "${st_b#* }" 2>/dev/null || echo "?")

    ~/.config/scripts/wallpaper.sh random >/dev/null 2>&1 || true
    sleep 6

    pid_a=$(pgrep -x nautilus | head -1)
    st_a=$(nautilus_state)
    col_a=$(sample_pixel "${st_a#* }" 2>/dev/null || echo "?")

    close="NO"; pindah="NO"; theme="NO"
    [[ -n "${pid_b:-}" && -n "${pid_a:-}" ]] && { [[ "$pid_b" != "$pid_a" ]] && close="YA"; }
    [[ -n "${st_b:-}" && -n "${st_a:-}" ]] && { [[ "${st_b#* }" != "${st_a#* }" ]] && pindah="YA"; }
    { [[ -n "${col_b:-}" && -n "${col_a:-}" && "$col_b" != "$col_a" ]] && theme="YA"; }

    printf '%-6s %-16s %-8s %-8s %-16s %-10s %-9s %-9s\n' \
        "$i" "${pid_a:-?}" "${st_a#* }" "$col_a" "$col_a" "$close" "$pindah" "$theme"
    printf '   before: pid=%s pos=%s color=%s\n' "${pid_b:-?}" "${st_b#* }" "${col_b:-?}"
    printf '   after : pid=%s pos=%s color=%s\n' "${pid_a:-?}" "${st_a#* }" "${col_a:-?}"
done
