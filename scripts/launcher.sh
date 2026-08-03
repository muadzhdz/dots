#!/usr/bin/env bash
set -euo pipefail

rofi -show drun \
     -display-drun "  Apps" \
     -drun-match-fields "name,generic,exec" \
     -matching fuzzy \
     -sort \
     -tokenize
