#!/bin/sh
set -eu
cd "$(dirname "$0")"
xcrun swiftc -O -warnings-as-errors -target arm64-apple-macos14.0 \
  SMC.swift main.swift -o magsafe-led -framework IOKit
