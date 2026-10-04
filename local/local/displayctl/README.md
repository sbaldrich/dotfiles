# displayctl

Disconnect and reconnect a display from the command line, as if it had been
unplugged, without BetterDisplay, displayplacer or any other third-party tool.

Written for a Dell shared through a KVM: when the KVM switches to the other
Mac, macOS keeps a "ghost" Dell and windows stay on it. Disconnecting the Dell
moves everything to the remaining display (the LG).

## Install

```bash
make restow PKG=local          # links this folder to ~/local/displayctl and the plugin into ~/local/swiftbar
~/local/displayctl/build.sh    # compiles displayctl and brightness-panel to ~/.local/bin (re-run after editing)
```

## Usage

```bash
displayctl list                          # all displays, plus saved ones that are disabled or offline
displayctl list --tsv                    # the same for scripts, with a SELECTOR column per display
displayctl status dell                   # prints connected/disconnected; exit 0 / 1, 2 on error
displayctl disconnect dell               # add --force to allow the built-in display
displayctl connect dell
displayctl main lg                       # make it the main display (permanent)
displayctl brightness dell               # read the brightness from the monitor
displayctl brightness dell 70            # set it in %; +10 / -10 adjust it
displayctl alias <name> <selector>       # save a display under a friendly name
```

A selector is an alias, a UUID, `vendor:model[:serial]` (vendor and model in
hex, serial in decimal, as `displayctl list` prints them) or a display ID.
Display IDs can change, so prefer an alias. A display disconnected without an
alias is saved under its `vendor:model:serial`, which is what to pass to
`connect`.

## Setting up the Dell alias

With the Dell connected, find it in `displayctl list`:

```
ID  VENDOR  MODEL   SERIAL     BUILTIN  STATE        ALIAS  NAME          UUID
2   0x10ac  0xa241  810763596  no       active,main  -      DELL U3425WE  BABDB05E-...
```

and save it:

```bash
displayctl alias dell 10ac:a241
```

The alias matches on vendor, model and serial, which come from the monitor
itself, with the UUID as a fallback. A monitor with a serial is matched on
vendor and serial alone, because the model can change with the input (the Dell
is `10ac:a241` on DisplayPort and `10ac:a243` over Thunderbolt). The display ID is saved too, and updated
whenever the Dell is seen, because a disabled display disappears from every
public display list and its last ID is the only way to turn it back on.
Everything is kept in `~/.config/displayctl/targets.json`.

## SwiftBar

`local/local/swiftbar/displays.5s.sh` runs every 5 seconds. The menu bar icon
shows two screens when two or more displays are on and one screen when only one
is, with a red warning if displayctl fails. The menu has a section per display,
whose icon shows whether it is on, with "Connect" or "Disconnect" and "Set as
Main Display", which moves the menu bar and Dock to it. Disconnect is left out
where displayctl would refuse it: the built-in display and the last active
display. "Brightness…" opens `brightness-panel`, a small panel with a slider
per display, just below the mouse pointer; Esc or a click elsewhere closes it.
Failed actions, such as switching off the last display, show a notification.
"Show displays" opens `displayctl list` in a terminal.

## Safety

- It refuses to disconnect the last active display, even with `--force`.
- It refuses to disconnect the built-in display unless `--force` is given.
- Disconnecting lasts for the login session only.
- Setting the main display is permanent, like dragging the menu bar in System
  Settings > Displays > Arrange. It only moves where (0, 0) is, so the
  arrangement stays as it was.

## Recovering

If a display stays dark:

1. `displayctl connect dell` (from SSH if no screen is usable).
2. Switch the KVM back, or unplug and replug the cable.
3. Log out, or reboot.

## How it works

`CGSConfigureDisplayEnabled`, a private CoreGraphics function, run inside a
normal `CGBeginDisplayConfiguration` / `CGCompleteDisplayConfiguration`
transaction completed with `.forSession`. It is looked up with `dlsym`, so if a
macOS update removes it, displayctl reports an error instead of failing to start.

Verified on macOS 26.6.2 (M3 Pro): disabled displays stay disabled after
displayctl exits, are re-enabled by their saved ID, and macOS restores the
previous arrangement and main display when they come back. Being private, the
function may change or disappear in a future macOS release.

The main display is the one at (0, 0), so `main` shifts every display by the
target's offset with the public `CGConfigureDisplayOrigin`.

Brightness uses DDC/CI, the monitor's control channel in the video cable,
through the private IOKit `IOAVService` functions (as MonitorControl and
BetterDisplay do). Each display is matched to its channel by product ID and
serial in the IORegistry. Both monitors here answer DDC, the Dell through the
KVM too, though a monitor that was just plugged in may need a few seconds. The
built-in display has no DDC; its brightness goes through the private
DisplayServices framework, like the brightness keys.
