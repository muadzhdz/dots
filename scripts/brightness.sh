#!/usr/bin/env bash
set -euo pipefail

STEP=5

DEVICE=""
for d in /sys/class/backlight/*; do
    if [[ -d "$d" ]]; then
        DEVICE="$(basename "$d")"
        break
    fi
done

if [[ -z "$DEVICE" ]]; then
    case "${1:-raise}" in
        raise) swayosd-client --brightness raise --min-brightness 0 ;;
        lower) swayosd-client --brightness lower --min-brightness 0 ;;
    esac
    exit 0
fi

MAX_RAW=$(cat "/sys/class/backlight/$DEVICE/max_brightness" 2>/dev/null || echo 255)
SAFE_MAX=$MAX_RAW
if [[ "$DEVICE" == *"amdgpu"* && "$MAX_RAW" -ge 65000 ]]; then
    SAFE_MAX=64000
fi

CUR_RAW=$(cat "/sys/class/backlight/$DEVICE/brightness" 2>/dev/null || echo 0)

if (( SAFE_MAX > 0 )); then
    CUR_PCT=$(( (CUR_RAW * 100 + SAFE_MAX / 2) / SAFE_MAX ))
else
    CUR_PCT=50
fi

(( CUR_PCT > 100 )) && CUR_PCT=100
(( CUR_PCT < 0 )) && CUR_PCT=0

ACTION="${1:-raise}"

case "$ACTION" in
    raise)
        NEW_PCT=$(( CUR_PCT + STEP ))
        (( NEW_PCT > 100 )) && NEW_PCT=100
        ;;
    lower)
        NEW_PCT=$(( CUR_PCT - STEP ))
        (( NEW_PCT < 0 )) && NEW_PCT=0
        ;;
    set)
        NEW_PCT="${2:-50}"
        (( NEW_PCT > 100 )) && NEW_PCT=100
        (( NEW_PCT < 0 )) && NEW_PCT=0
        ;;
    get)
        echo "$CUR_PCT"
        exit 0
        ;;
    *)
        echo "Usage: brightness.sh {raise|lower|set <pct>|get}"
        exit 1
        ;;
esac

if (( NEW_PCT == 0 )); then
    TARGET_RAW=0
elif (( NEW_PCT == 100 )); then
    TARGET_RAW=$SAFE_MAX
else
    TARGET_RAW=$(( (NEW_PCT * SAFE_MAX) / 100 ))
fi

brightnessctl -q -d "$DEVICE" s "$TARGET_RAW" 2>/dev/null || {
    echo "$TARGET_RAW" > "/sys/class/backlight/$DEVICE/brightness" 2>/dev/null || true
}

PROGRESS=$(awk "BEGIN {printf \"%.2f\", $NEW_PCT / 100}")
swayosd-client --custom-progress "$PROGRESS" --custom-progress-text "${NEW_PCT}%" --custom-icon display-brightness-symbolic >/dev/null 2>&1 || true
