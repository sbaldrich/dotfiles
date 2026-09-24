#!/bin/bash
# Float the focused window, resize it to a fraction of its monitor
# and centre it on that screen -- a "centered div" for windows.
#
# Pressing it again drops the window back into the tiling layout.
# Bound to 'c' in AeroSpace's service mode. Pass a different fraction to
# override the default, e.g. float-center.sh 0.5
#
# The window geometry is set by float-center.swift, compiled on first use and
# cached. Driving the Accessibility API from a small binary costs ~60ms where
# the equivalent System Events script costs ~130ms, which is worth a build step
# for something that runs on a keypress.

set -euo pipefail

RATIO="${1:-0.8}"
SRC="$(dirname "${BASH_SOURCE[0]}")/float-center.swift"
BIN="${XDG_CACHE_HOME:-$HOME/.cache}/aerospace/float-center"

if [[ ! -x $BIN || $SRC -nt $BIN ]]; then
    if ! command -v swiftc >/dev/null; then
        echo "float-center: swiftc not found, run 'xcode-select --install'" >&2
        exit 1
    fi
    mkdir -p "$(dirname "$BIN")"
    # Build to a temporary name so a second keypress during the first build
    # can't leave a half-written binary behind.
    build="$(mktemp "$BIN.XXXXXX")"
    swiftc -O -o "$build" "$SRC" && mv -f "$build" "$BIN" || { rm -f "$build"; exit 1; }
fi

IFS=$'\t' read -r layout pid screen < <(aerospace list-windows --focused \
    --format '%{window-layout}%{tab}%{app-pid}%{tab}%{monitor-appkit-nsscreen-screens-id}')

if [[ $layout == floating ]]; then
    aerospace layout tiling
    exit 0
fi

aerospace layout floating
exec "$BIN" "$pid" "$screen" "$RATIO"
