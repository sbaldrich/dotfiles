#!/bin/bash
# Compile boltframe.swift and install the binary to ~/.local/bin, where the
# Bolt SwiftBar plugin looks for it. Re-run after editing the source. Needs
# swiftc ('xcode-select --install').

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"

if ! command -v swiftc >/dev/null; then
    echo "build: swiftc not found, run 'xcode-select --install'" >&2
    exit 1
fi

mkdir -p "$BIN_DIR"
bin="$BIN_DIR/boltframe"
# Build to a temporary name so the plugin never runs a half-written binary.
build="$(mktemp "$bin.XXXXXX")"
if swiftc -O -o "$build" "$DIR/boltframe.swift"; then
    mv -f "$build" "$bin"
    echo "installed $bin"
else
    rm -f "$build"
    exit 1
fi
