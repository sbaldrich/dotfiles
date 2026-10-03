# magsafe-led

Turns the MagSafe 3 LED off and on from the command line (Apple Silicon, macOS 14+).
Extracted from MagSleep v1.3.7 (MIT; keep LICENSE). No dependencies, network, daemon, or files.

```sh
magsafe-led --check          # read-only compatibility check, no sudo
sudo magsafe-led off         # one-shot off (macOS may reset it on power events)
sudo magsafe-led off --keep  # stay off until Ctrl+C; reasserts every 3s and on power events
sudo magsafe-led on          # hand the LED back to macOS
```

`--keep` runs in the terminal, restores macOS control on Ctrl+C/SIGTERM/SIGHUP, and does not survive
reboot or SIGKILL (run `sudo magsafe-led on` afterward). Only the SMC key `ACLC` is written, only with
0 or 1, and only if it reports size 1 and type `ui8 `.

## Build and install

From the dotfiles repo (`make restow PKG=local` links this folder to `~/local/magsafe-led`):

```sh
~/local/magsafe-led/build.sh
sudo install -m 755 -o root -g wheel ~/local/magsafe-led/magsafe-led /usr/local/bin/magsafe-led
```

`build.sh` writes the binary next to the sources (into `~/local/magsafe-led`, not the repo).
`shasum -a 256 -c SHA256SUMS` checks the sources and the binary; the binary line matches the build
from Xcode's toolchain as of 2026-10-03 and may differ with another Swift version.

Install it root-owned: running `sudo` on a binary your own user can overwrite defeats the point.
ABI layout check (no hardware): `xcrun swiftc SMC.swift offline-checks.swift -o /tmp/chk -framework IOKit && /tmp/chk`

A review of upstream MagSleep, which motivated this extraction, is in `UPSTREAM-AUDIT.md`. Physical off/on, sleep/wake, charger reconnect and signal restoration have not been tested on hardware.
