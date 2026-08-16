#!/usr/bin/env bash
# Rice ISO build monitor
# Usage: rice-status.sh [status|tail|phase|log|help]

BUILD_DIR="$HOME/rice-iso"
LOG_DIR="$BUILD_DIR/build-logs"
CACHE_DIR="$HOME/.cache/omarchy/iso_edge/airootfs/var/cache/omarchy"
OFFLINE_DIR="$CACHE_DIR/mirror/offline"
MODEL_DIR="$CACHE_DIR/models"
RELEASE_DIR="$BUILD_DIR/release"
PACKAGES_FILE="$BUILD_DIR/builder/aur-packages.txt"

find_log() {
    local newest
    newest=$(ls -t "$LOG_DIR"/rice-build*.log 2>/dev/null | head -1)
    if [[ -z "$newest" ]]; then
        newest=$(ls -t /tmp/opencode/rice-build*.log 2>/dev/null | head -1)
    fi
    [[ -z "$newest" ]] && return 1
    echo "$newest"
}

is_building() {
    if docker ps 2>/dev/null | grep -q "archlinux"; then
        return 0
    fi
    if pgrep -f "omarchy-iso-make" >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

cmd_status() {
    echo "=== RICE ISO BUILD STATUS ==="
    if is_building; then
        echo "BUILD : BERJALAN (container/proses aktif)"
    else
        echo "BUILD : TIDAK ADA (idle)"
    fi

    local log
    log=$(find_log) || true
    if [[ -n "$log" ]]; then
        local mtime
        mtime=$(stat -c '%y' "$log" | cut -d. -f1)
        echo "LOG   : $log"
        echo "       (update terakhir $mtime)"
    else
        echo "LOG   : belum ada"
    fi

    echo "--- FASE TERAKHIR (tanpa progress xorriso) ---"
    if [[ -n "$log" ]]; then
        grep -v "xorriso : UPDATE\|libisofs : NOTE" "$log" | tail -3 | sed 's/^/  /'
    fi

    echo "--- MIRROR OFFLINE ---"
    if [[ -d "$OFFLINE_DIR" ]]; then
        local pkg_count manifest_count expected
        pkg_count=$(find "$OFFLINE_DIR" -maxdepth 1 -name '*.pkg.tar.zst' 2>/dev/null | wc -l)
        manifest_count=$(wc -l < "$OFFLINE_DIR/.rice-manifest" 2>/dev/null || echo 0)
        expected=$(grep -cEv '^\s*#|^\s*$' "$PACKAGES_FILE" 2>/dev/null || echo 0)
        local size
        size=$(du -sh "$OFFLINE_DIR" 2>/dev/null | cut -f1)
        echo "  ukuran     : $size"
        echo "  paket      : $pkg_count"
        echo "  manifest   : $manifest_count (expected AUR: $expected; resume OK jika >= $((expected + 1)))"
    else
        echo "  mirror offline belum ada"
    fi

    echo "--- MODEL VOICE ---"
    if [[ -f "$MODEL_DIR/ggml-small.bin" ]]; then
        local msize
        msize=$(du -h "$MODEL_DIR/ggml-small.bin" 2>/dev/null | cut -f1)
        echo "  ggml-small.bin: $msize ✓"
    else
        echo "  ggml-small.bin: BELUM ADA ✗"
    fi

    echo "--- ISO RELEASE ---"
    local iso
    iso=$(ls -t "$RELEASE_DIR"/*.iso 2>/dev/null | head -1)
    if [[ -n "$iso" ]]; then
        local isize idate
        isize=$(du -h "$iso" 2>/dev/null | cut -f1)
        idate=$(stat -c '%y' "$iso" | cut -d. -f1)
        echo "  $iso"
        echo "  ukuran: $isize | dibuat: $idate"
    else
        echo "  belum ada ISO di release/"
    fi
}

cmd_tail() {
    local log
    log=$(find_log) || { echo "belum ada log build"; exit 1; }
    tail -f "$log"
}

cmd_phase() {
    local log
    log=$(find_log) || { echo "belum ada log build"; exit 1; }
    grep -v "xorriso : UPDATE\|libisofs : NOTE" "$log" | tail -20
}

cmd_log() {
    local log
    log=$(find_log) || { echo "belum ada log build"; exit 1; }
    echo "$log"
}

cmd_help() {
    echo "Usage: rice-status.sh [command]"
    echo "  status (default) - ringkasan lengkap"
    echo "  tail             - ikuti log build secara live (tail -f)"
    echo "  phase            - 20 baris terakhir fase build"
    echo "  log              - path log aktif"
    echo ""
    echo "Log build baru otomatis disimpan di: $LOG_DIR (bukan /tmp)"
}

mkdir -p "$LOG_DIR"

case "${1-status}" in
    status) cmd_status ;;
    tail)   cmd_tail ;;
    phase)  cmd_phase ;;
    log)    cmd_log ;;
    help|-h) cmd_help ;;
    *) echo "usage: rice-status.sh {status|tail|phase|log|help}"; exit 1 ;;
esac