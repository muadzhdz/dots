#!/usr/bin/env bash
set -euo pipefail

if [[ -z ${ROFI_RETV:-} || $ROFI_RETV -eq 0 ]]; then
    cliphist list | while IFS=$'\t' read -r id preview; do
        [[ $preview == '[[ binary data'* ]] && continue
        label="$preview"
        if [[ $preview == SCREENSHOT:* ]]; then
            label="${preview#SCREENSHOT:}"
            label="${label##*/}"
        fi
        printf "%s\0info\x1f%s\n" "$label" "$id"
    done
elif [[ $ROFI_RETV -eq 1 ]]; then
    id=${ROFI_INFO:-}
    [[ -z $id ]] && exit 1
    content=$(cliphist decode "$id" 2>/dev/null) || exit 1
    content=${content%$'\n'}
    if [[ $content == SCREENSHOT:* ]]; then
        path="${content#SCREENSHOT:}"
        wl-copy < "$path"
    else
        echo -n "$content" | wl-copy
    fi
    notify-send "Clipboard" "Restored" -t 1000
fi
