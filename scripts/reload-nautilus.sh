#!/usr/bin/env bash
set -euo pipefail
if pgrep -x nautilus >/dev/null 2>&1; then
    nautilus -q 2>/dev/null || true
fi
