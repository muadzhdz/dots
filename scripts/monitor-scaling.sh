#!/usr/bin/env bash
set -euo pipefail

SCALES=(1.0 1.25 1.6 2.0 3.0 4.0)

monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')
scale=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .scale')

current_idx=-1
for i in "${!SCALES[@]}"; do
    if [[ $(bc <<< "${SCALES[$i]} == $scale") -eq 1 ]]; then
        current_idx=$i
        break
    fi
done

if [[ $current_idx -eq -1 ]]; then
    current_idx=0
fi

if [[ ${1:-} == "--reverse" ]]; then
    new_idx=$((current_idx - 1))
    [[ $new_idx -lt 0 ]] && new_idx=$((${#SCALES[@]} - 1))
else
    new_idx=$((current_idx + 1))
    [[ $new_idx -ge ${#SCALES[@]} ]] && new_idx=0
fi

new=${SCALES[$new_idx]}

[[ $(bc <<< "$new == $scale") -eq 1 ]] && exit 0

hyprctl eval "hl.monitor({output='$monitor',mode='preferred',position='auto',scale='$new'})" 2>/dev/null
