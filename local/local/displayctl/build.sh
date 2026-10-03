#!/bin/bash
# Compile displayctl.swift and install the binary to ~/.local/bin/displayctl.
# Re-run after editing the source. Needs swiftc ('xcode-select --install').

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/displayctl.swift"
BIN="$HOME/.local/bin/displayctl"

if ! command -v swiftc >/dev/null; then
    echo "build: swiftc not found, run 'xcode-select --install'" >&2
    exit 1
fi

mkdir -p "$(dirname "$BIN")"
# Build to a temporary name so the SwiftBar plugin never runs a half-written binary.
build="$(mktemp "$BIN.XXXXXX")"
if swiftc -O -o "$build" "$SRC"; then
    mv -f "$build" "$BIN"
    echo "installed $BIN"
else
    rm -f "$build"
    exit 1
fi
