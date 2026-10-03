#!/bin/bash
# Compile displayctl.swift and brightness-panel.swift and install the binaries
# to ~/.local/bin. Re-run after editing the sources. Needs swiftc
# ('xcode-select --install').

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"

if ! command -v swiftc >/dev/null; then
    echo "build: swiftc not found, run 'xcode-select --install'" >&2
    exit 1
fi

mkdir -p "$BIN_DIR"
for name in displayctl brightness-panel; do
    bin="$BIN_DIR/$name"
    # Build to a temporary name so the SwiftBar plugin never runs a half-written binary.
    build="$(mktemp "$bin.XXXXXX")"
    if swiftc -O -o "$build" "$DIR/$name.swift"; then
        mv -f "$build" "$bin"
        echo "installed $bin"
    else
        rm -f "$build"
        exit 1
    fi
done
