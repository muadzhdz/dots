#!/usr/bin/env bash
set -euo pipefail

pkill -x nautilus 2>/dev/null || true
setsid nautilus >/dev/null 2>&1 &
