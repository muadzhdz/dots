#!/usr/bin/env bash
set -euo pipefail
# Rice ISO build monitor
# Usage: rice-status.sh [status|tail|phase|log|help]

BUILD_DIR="$HOME/rice-iso"
LOG_DIR="$BUILD_DIR/build-logs"
CACHE_DIR="$HOME/.cache/rice/iso_edge/airootfs/var/cache/rice"
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
    if pgrep -f "rice-iso-make" >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

human_size() {
    local bytes="$1" n
    [[ $bytes =~ ^[0-9]+$ ]] || { echo "?"; return; }
    if (( bytes >= 1073741824 )); then n=$(( bytes * 10 / 1073741824 )); echo "$((n / 10)).$((n % 10))G"
    elif (( bytes >= 1048576 )); then n=$(( bytes * 10 / 1048576 )); echo "$((n / 10)).$((n % 10))M"
    elif (( bytes >= 1024 )); then n=$(( bytes * 10 / 1024 )); echo "$((n / 10)).$((n % 10))K"
    else echo "${bytes}B"; fi
}

# Aggregate RX rate from /proc/net/dev, sampled between invocations so live
# mode shows a real ↓ speed instead of a one-shot counter.
net_rate() {
    local f=/tmp/.rice-status-net prev_bytes prev_ns now_bytes now_ns rate
    now_bytes=$(awk '{s += $2} END {print s}' /proc/net/dev 2>/dev/null) || return 0
    [[ $now_bytes =~ ^[0-9]+$ ]] || return 0
    now_ns=$(date +%s%N)
    if [[ -f $f ]]; then
        read -r prev_bytes prev_ns < "$f"
        if [[ $prev_bytes =~ ^[0-9]+$ && $prev_ns =~ ^[0-9]+$ ]] && (( now_ns > prev_ns )); then
            rate=$(( (now_bytes - prev_bytes) * 1000000000 / (now_ns - prev_ns) ))
            printf '%s' "$(human_size "$rate")/s"
            return 0
        fi
    fi
    printf '%s %s' "$now_bytes" "$now_ns" > "$f"
}

# Real-time view of what the build is doing right now: current phase, AUR
# package being built, active pacman downloads (with sizes), network rate,
# and pacstrap package-install progress.
cmd_process() {
    echo "--- PROSES REAL-TIME ---"
    local log
    log=$(find_log) || { echo "  belum ada log build"; return 0; }

    local aur_total aur_done aur_current phase
    aur_total=$(grep -cEv '^\s*#|^\s*$' "$PACKAGES_FILE" 2>/dev/null || echo 0)
    aur_done=$(grep -c "Building AUR:" "$log" 2>/dev/null || echo 0)
    aur_current=$(grep "Building AUR:" "$log" | tail -1 | sed 's/.*Building AUR: //')
    if [[ -n $aur_current ]]; then
        phase="AUR build: $aur_current ($aur_done/$aur_total)"
    elif grep -q "Building rice-runtime" "$log"; then
        phase="build rice-runtime"
    elif grep -q "Installing packages to '/var/cache/work" "$log"; then
        phase="pacstrap ke airootfs"
    elif grep -q "\[mkarchiso\]" "$log"; then
        phase="mkarchiso (copy/initramfs)"
    elif grep -q "xorriso" "$log"; then
        phase="assembly ISO (xorriso)"
    elif grep -q "Done!" "$log"; then
        phase="SELESAI"
    else
        phase="fase awal (sync/init)"
    fi
    echo "  fase        : $phase"

    local mtime now
    mtime=$(stat -c %Y "$log" 2>/dev/null || echo 0)
    now=$(date +%s)
    if (( now - mtime <= 30 )); then
        echo "  log         : aktif (update <30 dtk lalu)"
    else
        echo "  log         : diam $((now - mtime)) detik"
    fi

    local ddir total
    ddir=$(ls -dt /var/cache/pacman/pkg/download-* 2>/dev/null | head -1)
    if [[ -n $ddir ]]; then
        total=$(du -sb "$ddir" 2>/dev/null | cut -f1)
        echo "  download    : $(human_size "$total") (aktif)"
        local fname fsize
        while read -r fname fsize; do
            [[ -n $fname ]] || continue
            echo "    └ $fname ($(human_size "$fsize"))"
        done < <(find "$ddir" -maxdepth 1 -type f -printf '%f %s\n' 2>/dev/null | sort -k2 -rn | head -3)
    else
        echo "  download    : tidak ada (idle)"
    fi

    local rate
    rate=$(net_rate)
    [[ -n $rate ]] && echo "  jaringan    : ↓ $rate"

    # Pacstrap progress: count installed package dirs in the work airootfs
    # against the last "Packages (N)" target from the log.
    local cid installed_str exp
    cid=$(docker ps -q 2>/dev/null | head -1)
    if [[ -n $cid ]] && grep -q "Installing packages to" "$log"; then
        installed_str=$(timeout 6 docker exec "$cid" sh -c 'find /var/cache/work/x86_64/airootfs/var/lib/pacman/local -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l' 2>/dev/null)
        if [[ $installed_str =~ ^[0-9]+$ ]] && (( installed_str > 0 )); then
            exp=$(grep -oE "Packages \(([0-9]+)\)" "$log" | tail -1 | grep -oE "[0-9]+$")
            echo "  instalasi   : $installed_str paket terpasang${exp:+ / $exp target}"
        fi
    fi

    echo "  log terakhir: $(grep -v "xorriso : UPDATE\|libisofs : NOTE" "$log" | tail -1 | cut -c1-90)"
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

    cmd_process

    echo "--- MIRROR OFFLINE ---"
    if [[ -d "$OFFLINE_DIR" ]]; then
        local pkg_count manifest_count expected
        pkg_count=$(find "$OFFLINE_DIR" -maxdepth 1 -name '*.pkg.tar.zst' 2>/dev/null | wc -l)
        # Guard with -f first: a failed < redirect prints a shell error even
        # with 2>/dev/null (e.g. while the mirror is mid-rebuild with no
        # manifest yet), so count only when the file actually exists.
        manifest_count=0
        [[ -f "$OFFLINE_DIR/.rice-manifest" ]] && manifest_count=$(wc -l < "$OFFLINE_DIR/.rice-manifest")
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

cmd_live() {
    local interval="${1:-10}"
    [[ "$interval" =~ ^[0-9]+$ ]] || interval=10
    local log
    log=$(find_log) || { echo "belum ada log build"; exit 1; }
    while true; do
        clear
        cmd_status
        echo ""
        echo "  (live mode — refresh tiap ${interval}s | Ctrl+C untuk keluar)"
        sleep "$interval"
    done
}

cmd_log() {
    local log
    log=$(find_log) || { echo "belum ada log build"; exit 1; }
    echo "$log"
}

cmd_help() {
    echo "Usage: rice-status.sh [command]"
    echo "  status (default) - ringkasan lengkap + proses real-time"
    echo "  tail             - ikuti log build secara live (tail -f)"
    echo "  live [detik]     - status auto-refresh (default 10 detik)"
    echo "  phase            - 20 baris terakhir fase build"
    echo "  log              - path log aktif"
    echo ""
    echo "Log build baru otomatis disimpan di: $LOG_DIR (bukan /tmp)"
}

mkdir -p "$LOG_DIR"

case "${1-status}" in
    status) cmd_status ;;
    tail)   cmd_tail ;;
    live)   cmd_live "$2" ;;
    phase)  cmd_phase ;;
    log)    cmd_log ;;
    help|-h) cmd_help ;;
    *) echo "usage: rice-status.sh {status|tail|phase|log|help}"; exit 1 ;;
esac