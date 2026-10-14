# boltframe

Covers every display with a red border, a faint red wash and "Keyboard isn't
connected to this Mac" while the Logi Bolt keyboard is switched to another
computer, so typing at the wrong Mac doesn't go unnoticed.

It's started by the Bolt SwiftBar plugin (`local/local/swiftbar/bolt.py`),
which watches the receiver and also shows in the menu bar which devices are
connected here.

## Install

On each Mac with a Bolt receiver:

```bash
make restow PKG=local          # links this folder to ~/local/boltframe and the plugin into ~/local/swiftbar
~/local/boltframe/build.sh     # compiles boltframe to ~/.local/bin (re-run after editing)
```

Then restart SwiftBar. It needs:

- swiftc (`xcode-select --install`).
- uv at `/opt/homebrew/bin/uv`, which the plugin's shebang names. uv fetches
  `hidapi` the first time the plugin runs.
- SwiftBar's plugin folder set to `~/local/swiftbar`.

Without `boltframe` built, the plugin still works and just shows no overlay.

## What it does

The menu bar icon:

| Icon                         | Meaning                                                  |
| ---------------------------- | -------------------------------------------------------- |
| Green device icons           | Those devices are connected to this Mac                  |
| Red outline keyboard         | The keyboard is paired here but connected elsewhere      |
| Orange outline keyboard      | Receiver present, nothing connected                      |
| Grey keyboard with ellipsis  | No receiver plugged in (normal away from the desk)       |
| Red warning triangle         | Receiver plugged in, but another app holds it exclusively |

The overlay appears when the keyboard leaves this Mac and goes away when it
comes back. It's click-through, since the mouse may still be here, and also
goes away on a key press on this Mac: that must be another keyboard, such as
the built-in one with the lid open, so you're working here on purpose. It
stays closed until the keyboard comes back and leaves again.

A keyboard that is switched off or out of range looks the same to the
receiver as one connected to another computer, so it shows the overlay too.

## Turning it off

From the plugin's menu:

- **Hide Overlay** (only while it's up) closes it until the keyboard comes
  back and leaves again.
- **Show Overlay When Keyboard Leaves** turns it off and on for good. Off
  means `~/.config/bolt/overlay-off` exists; the running plugin checks for it
  every second, so `touch` and `rm` on that file work too.

To change the label or the wash, edit `label` or the `0.15` opacity at the top
of `boltframe.swift` and re-run `build.sh`.

## How it works

The plugin opens the receiver's HID++ interface (vendor usage page `0xFF00`),
turns on its wireless notifications and asks it to re-announce every paired
device. Each connect or disconnect then arrives as a `0x41` notification
carrying the device's slot, its kind and whether the link is up.

hidapi opens devices exclusively on macOS, which locked out Logi Options+ and
the new copy of the plugin SwiftBar starts after every wake, leaving it stuck
on "No Bolt receiver found". The Python binding doesn't expose the switch, so
the plugin calls `hid_darwin_set_open_exclusive(0)` from the compiled module
through `ctypes`.

`boltframe` is a borderless, transparent window per display at screen-saver
level, on every Space and over full-screen apps, redrawn when displays change.
It detects key presses by polling the system idle time for key-down events,
which needs no Accessibility or Input Monitoring permission, and exits if its
parent goes away, so it can't outlive the plugin.

## Troubleshooting

- **The overlay doesn't close on a key press, or shows an old label:** the
  installed binary is out of date. Re-run `build.sh`.
- **SwiftBar shows a `bolt.cpython-*.pyc` plugin with "exec format error":**
  importing `bolt.py` with Python left a `__pycache__` folder in the plugin
  folder, and SwiftBar runs everything it finds there. Delete the folder; set
  `PYTHONDONTWRITEBYTECODE=1` when testing the plugin from Python.
- **The menu shows the red warning triangle:** another app opened the
  receiver exclusively. Quit it; the plugin retries every 5 seconds.
