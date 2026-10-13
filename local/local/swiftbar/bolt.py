#!/usr/bin/env -S /opt/homebrew/bin/uv run --quiet --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["hidapi"]
# ///
# <xbar.title>Logi Bolt link status</xbar.title>
# <xbar.desc>Shows whether a device paired to this Mac's Bolt receiver is currently connected.</xbar.desc>
# <swiftbar.type>streamable</swiftbar.type>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
#
# Replace /Users/YOU/.local/bin/uv with the output of `which uv`.
# Untested against real hardware.

import ctypes
import subprocess
import sys
import time
from pathlib import Path

import hid

VID, PID = 0x046D, 0xC548      # Logitech Bolt receiver
HIDPP_PAGE = 0xFF00            # vendor usage page carrying HID++
RECEIVER = 0xFF                # device index for the receiver itself

SET_REG, GET_REG, ERROR = 0x80, 0x81, 0x8F
REG_NOTIFY_FLAGS = 0x00        # which notifications the receiver sends
REG_CONNECTION = 0x02          # writing 0x02 makes it re-announce every paired device
DEVICE_CONNECTION = 0x41       # notification: a paired device linked/unlinked
LINK_DOWN = 0x40               # bit in the 0x41 flags byte: link NOT established
KIND_MASK = 0x0F               # low nibble of the 0x41 flags byte: device kind

# Device kind -> (SF Symbol, label). Unlisted kinds fall back to UNKNOWN_KIND.
KINDS = {
    0x01: ("keyboard.fill", "Keyboard"),
    0x02: ("computermouse.fill", "Mouse"),
    0x03: ("keyboard.fill", "Numpad"),
    0x08: ("computermouse.fill", "Trackball"),
    0x09: ("rectangle.and.hand.point.up.left.fill", "Touchpad"),
}
UNKNOWN_KIND = ("dot.radiowaves.left.and.right", "Device")

KEYBOARD = 0x01
OVERLAY = Path.home() / ".local/bin/boltframe"  # see local/boltframe; skipped if not built

RED, ORANGE, GREEN, GREY = "#FF3B30", "#FF9500", "#34C759", "#8E8E93"
# Away from the desk there's no receiver, which is normal, so it isn't red.
NO_RECEIVER = ("keyboard.badge.ellipsis", GREY, "No Bolt receiver found")
RECEIVER_BUSY = ("exclamationmark.triangle.fill", RED, "Bolt receiver found, but another app holds it exclusively")


def emit(online, elsewhere=False):
    """Push one menu bar update to SwiftBar. online: {slot: kind} of devices linked
    to this Mac; elsewhere: the keyboard is paired here but linked to another computer."""
    devices = sorted(online.items(), key=lambda s: (s[1], s[0]))  # keyboard before mouse
    icons = [KINDS.get(kind, UNKNOWN_KIND)[0] for _, kind in devices]
    tips = [f"{KINDS.get(kind, UNKNOWN_KIND)[1]} connected (slot {slot})" for slot, kind in devices]
    if elsewhere:
        show(["keyboard", *icons], RED, ["Keyboard isn't connected to this Mac", *tips])
    elif devices:
        show(icons, GREEN, tips)
    else:
        show(["keyboard"], ORANGE, ["Receiver present, nothing connected here"])


def emit_problem(problem):
    icon, color, tip = problem
    show([icon], color, [tip])


def show(icons, color, tips):
    print("~~~")
    # sfimage= is always rendered as a template (monochrome) image, so sfcolor is
    # ignored there; an inline :symbol: in the title is what sfcolor tints.
    title = " ".join(f":{icon}:" for icon in icons)
    print(f"{title} | sfcolor={color} sfsize=16")
    print("---")
    print("\n".join(tips))
    sys.stdout.flush()


def share_receiver():
    """hidapi opens devices exclusively on macOS, which locks out Logi Options+
    and the new copy of this plugin SwiftBar starts after every wake. The Python
    binding doesn't expose the switch, so call the C function it's built from."""
    try:
        ctypes.CDLL(hid.__file__).hid_darwin_set_open_exclusive(0)
    except (OSError, AttributeError):  # not macOS, or a build without it
        pass


def open_receiver():
    """The receiver's HID++ interface, or None if it isn't plugged in. Raises
    OSError if it is but can't be opened."""
    candidates = [d for d in hid.enumerate(VID, PID) if d["usage_page"] == HIDPP_PAGE]
    if not candidates:
        return None
    candidates.sort(key=lambda d: d["usage"] != 0x0001)  # prefer the short-report collection
    dev = hid.device()
    dev.open_path(candidates[0]["path"])
    return dev


def register(dev, sub_id, reg, params=(0, 0, 0), timeout=1.0):
    """Send a HID++ 1.0 register request to the receiver and wait for its reply."""
    dev.write([0x10, RECEIVER, sub_id, reg, *params])
    deadline = time.time() + timeout
    while time.time() < deadline:
        r = dev.read(20, 100)
        if not r or len(r) < 5 or r[1] != RECEIVER:
            continue
        if r[2] == sub_id and r[3] == reg:
            return r
        if r[2] == ERROR and r[3] == sub_id and r[4] == reg:
            return None
    return None


def listen(dev):
    # Turn on wireless connect/disconnect notifications without clobbering
    # flags other software (e.g. Logi Options+) may already have set.
    current = register(dev, GET_REG, REG_NOTIFY_FLAGS)
    flags = list(current[4:7]) if current else [0, 0, 0]
    flags[1] |= 0x01  # 0x000100 = wireless notifications
    register(dev, SET_REG, REG_NOTIFY_FLAGS, flags)

    online = {}
    emit(online)

    # Ask the receiver to announce the current state of every paired device.
    dev.write([0x10, RECEIVER, SET_REG, REG_CONNECTION, 0x02, 0x00, 0x00])

    keyboards = set()  # slots of paired keyboards, linked here or not
    elsewhere = False
    overlay = None     # boltframe process, started when the keyboard leaves
    try:
        while True:
            r = dev.read(20, 1000)
            if not (r and len(r) >= 5 and r[2] == DEVICE_CONNECTION):
                continue
            slot, kind = r[1], r[4] & KIND_MASK
            if kind == KEYBOARD:
                keyboards.add(slot)
            if r[4] & LINK_DOWN:
                online.pop(slot, None)
            else:
                online[slot] = kind
            was_elsewhere = elsewhere
            elsewhere = bool(keyboards) and not keyboards & online.keys()
            # Only on the change: a key pressed on this Mac closes the overlay,
            # and it stays closed until the keyboard comes back and leaves again.
            if elsewhere and not was_elsewhere:
                overlay = start_overlay()
            elif was_elsewhere and not elsewhere:
                overlay = stop_overlay(overlay)
            emit(online, elsewhere)
    finally:
        stop_overlay(overlay)


def start_overlay():
    """Start boltframe. Returns the process, or None."""
    try:
        return subprocess.Popen([OVERLAY], stdin=subprocess.DEVNULL,
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except OSError:  # not built
        return None


def stop_overlay(overlay):
    """Take the overlay down if it's still up."""
    if overlay is not None and overlay.poll() is None:
        overlay.terminate()
    return None


def main():
    share_receiver()
    while True:
        try:
            dev = open_receiver()
        except OSError:
            emit_problem(RECEIVER_BUSY)
            time.sleep(5)
            continue
        if dev is None:
            emit_problem(NO_RECEIVER)
            time.sleep(5)
            continue
        try:
            listen(dev)
        except OSError:  # receiver unplugged or read failed
            emit_problem(NO_RECEIVER)
            time.sleep(2)
        finally:
            dev.close()


if __name__ == "__main__":
    main()
