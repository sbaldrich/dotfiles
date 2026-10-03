# MagSleep audit — 2026-10-02

> **Historical record.** This audits upstream MagSleep v1.3.7, not the code in this folder. The supporting evidence it cites (upstream test/build logs, Sigstore provenance, signature-tamper note, and the CLI argument-check log) was removed during cleanup. The CLI described under "Extraction and handoff" is the earlier, larger variant; this folder now holds the slimmer one.

Recommendation: extract the LED controller for this use case. I do not give MagSleep v1.3.7 an unconditional installation approval. No malicious behavior was found in the first-party source reviewed, but its updater dependency has published security advisories and its privileged installer overstates the protection provided by ad-hoc signatures.

## Scope and evidence

- Repository: https://github.com/realAbitbol/MagSleep
- Current master examined: `cc6994a52e9fa9271b4d1b5bce0d37b79d0691b5`.
- Latest release: v1.3.7, published 2026-09-22, source commit `89a52aba994cfc434409c8dbfbecc9150a2fe6f5`.
- Master differs from that release only in README, changelog, and appcast. Runtime, installer, packaging, and dependency code are unchanged.
- Reviewed all first-party Swift runtime files, shell/Python release/install scripts, package declarations, plists, and GitHub workflows, plus the core test suite. Inspected the release ZIP without launching its app or helper.
- ZIP SHA-256: `3a6709f08ba1246e11fbbd13663712674250d8a67518c7e714ab80870a046166`, matching GitHub's asset digest.
- GitHub/Sigstore build provenance verified with `gh attestation verify`; source commit, tag, release workflow, and github-hosted runner match. Verified workflow: https://github.com/realAbitbol/MagSleep/actions/runs/35770187504
- The release's Sparkle Ed25519 archive signature verifies against the public key embedded in its Info.plist.
- `codesign --verify --deep --strict` passes on the downloaded application. Its signature is ad-hoc, with no TeamIdentifier and no main-app entitlements. This is integrity evidence, not authenticated publisher identity or notarization.
- Bundled install/uninstall scripts match the reviewed source. The root helper links Apple system libraries/frameworks; it does not link Sparkle.

## Findings

### 1. High priority: outdated updater with known high-severity advisories

`Package.resolved:11` pins Sparkle **2.9.5**; the downloaded framework also reports **2.9.5**. Sparkle published these advisories on 2026-08-17, both fixed in **2.9.6**:

- [GHSA-3x7w-j75x-ppq5](https://github.com/sparkle-project/Sparkle/security/advisories/GHSA-3x7w-j75x-ppq5): race between resolving a download path and moving the unresolved path, enabling privileged file moves under affected system-domain installations. Upstream severity: High, CVSS 7.0; local, high-complexity attack, with practical filename constraints.
- [GHSA-4v99-qgq9-6pxp](https://github.com/sparkle-project/Sparkle/security/advisories/GHSA-4v99-qgq9-6pxp): privileged cache cleanup follows user-controlled symlinks. Upstream severity: High, CVSS 7.8; requires the host updater/CLI itself to run as root.

Presence of the affected dependency is confirmed. Exploitability in MagSleep's usual launch/update configuration has NOT been demonstrated. The menu-bar app normally runs as the user, and its separate root LED helper does not use Sparkle; therefore the second advisory is not automatically reachable just because the LED helper is privileged. The first depends on the updater's installation privilege path. Nevertheless, shipping this dependency after fixes were published is an avoidable blocker to a clean audit pass. Update to a patched version and reassess; extracting the controller removes Sparkle entirely.

### 2. Medium: privileged installer does not authenticate its publisher

`scripts/install-helper.sh:41–65` verifies any valid app signature and compares the helper to a cdhash stored inside the same app. The app and helper are ad-hoc signed. Someone who can modify the bundle can change the privileged script/helper and hashes and re-sign the app without a developer identity. The hash check is also skipped if the pin is missing. `Sources/MagSleep/HelperManager.swift:487–527` executes a script from that bundle as root using an administrator authorization prompt; the script's self-check happens after root shell execution has already begun.

Confirmed with a harmless local test: copied the release app, appended a comment to its privileged installer, ad-hoc re-signed it, and reran the installer's signature/hash checks. Strict deep signature verification passed and the helper cdhash still matched. No app, helper, or installer was executed.

This does not establish a remote attack or password-free escalation: admin authorization is still required, and modification requires access to the bundle. It shows that these checks cannot establish origin or protect against deliberate re-signing, despite the stronger claims in the comments. The actual release's independently verified attestation is useful initial download provenance, but it is not enforced by this runtime install path. Root code should be sourced from an independently trusted build and a protected installation boundary.

### 3. Medium reliability: reported success does not prove the LED changed or restored

`Sources/MagSleepHelper/MagSleepHelperMain.swift:184–198, 203–233, 296–304` logs persistence and SMC errors but still returns the precomputed successful configuration ACK. Disabling sets `enabled=false`; `reassertActiveMode()` at 572–575 then skips retries, so a failed restoration can leave the LED off despite a successful response. The `--reset` path at 619–621 ignores SMC errors and exits 0. The uninstall script similarly tolerates failures and ends with a success message.

The configuration state and menu/AppleScript status therefore cannot certify physical LED state. Existing tests exercise the pure handler and state logic, not the root SMC side effects. The extracted one-shot commands return failure when the SMC write fails; keep-off retries failures and signal restoration returns failure if it cannot restore.

### 4. Low: broad local socket access and residual denial-of-service surface

`Sources/MagSleepHelper/SocketServer.swift:75–79, 147–171, 187–219` creates a 0666 socket. `isAllowedPeer` at helper-main 239–246 allows root and any process running as the current console user, not only MagSleep's signed application. Accepted commands are a small hardcoded LED/config vocabulary; I found no command that accepts an arbitrary SMC key, executable path, or shell code.

Peer authorization occurs after reading a complete request. Other local users can occupy the 32 client slots without finishing a request, temporarily blocking legitimate control. A 10-second idle limit and size/client caps limit accumulation but do not prevent sustained local flooding. This is an availability/tampering concern, not evidence of arbitrary root execution through the socket.

### 5. Low: release assurances are weaker than their wording

`scripts/virustotal-scan.sh` deliberately returns success for missing credentials, failed scans, pending results, and completed scans with detections. CI does not block publication on a malware verdict. Release v1.3.7 reports 0 malicious / 75 engines; that report is not a proof that the logic or privilege boundary is secure, and I did not independently rerun VirusTotal.

Release Actions use mutable major-version references rather than immutable commit pins, and release secrets/write tokens are available job-wide. Build provenance verifies which workflow built this downloaded artifact; it does not prevent the maintainer, a compromised account, or a compromised build dependency from supplying malicious source/workflow changes.

## Behavior and privacy observations

- The app uses a persistent root LaunchDaemon. Quitting the menu-bar app does not stop it. Disabled restores system control but leaves the daemon installed/running. Complete removal uses the uninstall path.
- Always Off reasserts every three seconds, in addition to power events. Optional night scheduling invokes the local `corebrightnessdiag sunschedule` diagnostic at startup and every 30 minutes even if night scheduling is disabled (`startSunScheduleTimer()` is unconditional).
- No credential capture, first-party analytics, arbitrary remote shell execution, or unrelated SMC writes were found in the first-party runtime source. Network behavior includes automatic HTTPS Sparkle update checks every 12 hours, downloads when updating, and user-initiated GitHub/Ko-fi links. This is not an exhaustive audit of all Sparkle internals or dynamic network traffic.
- LED control is undocumented hardware access. Upstream supports Apple Silicon MagSafe 3 on macOS 14+. Neither the source nor unit tests prove future firmware compatibility or hardware safety across every model.

## Verification performed

Commands run on macOS 26.6.2 / arm64, Apple Swift 6.2.3:

1. `git clone https://github.com/realAbitbol/MagSleep.git` into a temporary audit checkout; git revision/history/file inspection and source review using `rg`, `sed`, and line-numbered reads.
2. GitHub Releases API query and download of `MagSleep-1.3.7.zip` over HTTPS; `shasum -a 256` matches the release digest.
3. `gh attestation verify MagSleep-1.3.7.zip --repo realAbitbol/MagSleep --format json` succeeds. Verification result inspected for exact source commit/workflow/tag/runner and artifact digest.
4. `ditto -x -k` extracts the ZIP; `codesign --verify --deep --strict --verbose=2`, signature/entitlement inspection, `plutil -p`, and `otool -L` inspect the release without launching it. Bundled scripts compared with `diff -u`.
5. Ed25519 signature verification via a local Swift/CryptoKit script, using the current appcast's v1.3.7 enclosure signature and bundled `SUPublicEDKey`: passes.
6. `xcrun swift test`: **95 tests pass**, zero failures. Logs saved alongside this report.
7. `xcrun swift build -c release --arch arm64`: passes, no reported warnings/errors.
8. On an isolated copy of the downloaded app only: comment alteration, `codesign --force --sign - --deep`, then `codesign --verify --deep --strict` and bundled helper cdhash comparison: both checks pass. Installer/app/helper execution not performed.
9. Extracted CLI: `xcrun swiftc -O -warnings-as-errors -target arm64-apple-macos14.0 SMC.swift main.swift -o magsafe-led -framework IOKit`: passes. `file` confirms arm64; `otool -L` shows only system libraries/frameworks.
10. Eight CLI help/invalid-argument/non-root off/on/keep cases: expected exits, with all write requests rejected before hardware access. `cli-verification.txt` records them.
11. Offline SMC ABI offset/stride, key-encoding and invalid-key checks: pass without hardware access.
12. `./magsafe-led --check`: read-only result on this Mac is `ACLC: size=1, type=ui8 `.
13. Original Aviary checkout and cloned MagSleep tracked files remain unchanged.

Not performed: privileged installer/uninstaller execution, app launch/update, dynamic network capture, physical LED off/on, charger reconnect, sleep/wake, signal-restoration hardware checks, simulator/model matrix, or independent second-agent review. No sudo, daemon installation, Gatekeeper/quarantine bypass, or LED write was performed. These limits preclude claiming fully tested operation or a comprehensive security certification.

## Extraction and handoff

Outcome: dependency-free CLI extracted, compiled, and checked without LED writes; supports manual off/on and foreground keep-off with power events and three-second retry.
Branch: not applicable; read-only repository audit, standalone deliverables outside repositories.
Base commit: upstream v1.3.7 at `89a52aba994cfc434409c8dbfbecc9150a2fe6f5`.
Worktree: no task worktree needed; no tracked repository modifications.
Commits: none.
Verification: recorded above.
Review: not requested; this report is the audit, not an independent implementation approval.
Decisions made: retain only one-shot SMC code; allow ACLC 0/1 only; remove updater, privileged installer, socket, persistent service, settings, scheduling, and UI; add optional foreground enforcement and error reporting.
Known limitations or residual risk: root still required for writes; undocumented SMC behavior; physical LED and keep-off lifecycle remain untested; brief flashes possible; foreground keeper must be stopped before separate on command; no persistence across reboot; crash/SIGKILL can leave an override requiring manual reset.
Specification deviations: none; no Aviary specifications are affected.
Recommended merge order or dependencies: no merge, installation, or dependency changes required. Before considering the original app, update Sparkle to a patched version and fix/reassess privilege and restoration findings.
