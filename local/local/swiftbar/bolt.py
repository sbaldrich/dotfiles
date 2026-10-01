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

import sys
import time

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


def emit(online):
    """Push one menu bar update to SwiftBar. online: None = no receiver, else {slot: kind}."""
    if online is None:
        icons, color = ["keyboard.badge.ellipsis"], "#FF3B30"
        tips = ["No Bolt receiver found"]
    elif online:
        devices = sorted(online.items(), key=lambda s: (s[1], s[0]))  # keyboard before mouse
        icons = [KINDS.get(kind, UNKNOWN_KIND)[0] for _, kind in devices]
        color = "#34C759"
        tips = [f"{KINDS.get(kind, UNKNOWN_KIND)[1]} connected (slot {slot})" for slot, kind in devices]
    else:
        icons, color = ["keyboard"], "#FF9500"
        tips = ["Receiver present, nothing connected here"]
    print("~~~")
    # sfimage= is always rendered as a template (monochrome) image, so sfcolor is
    # ignored there; an inline :symbol: in the title is what sfcolor tints.
    title = " ".join(f":{icon}:" for icon in icons)
    print(f"{title} | sfcolor={color} sfsize=16")
    print("---")
    print("\n".join(tips))
    sys.stdout.flush()


def open_receiver():
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

    while True:
        r = dev.read(20, 1000)
        if r and len(r) >= 5 and r[2] == DEVICE_CONNECTION:
            slot = r[1]
            if r[4] & LINK_DOWN:
                online.pop(slot, None)
            else:
                online[slot] = r[4] & KIND_MASK
            emit(online)


def main():
    while True:
        dev = None
        try:
            dev = open_receiver()
            if dev is None:
                emit(None)
                time.sleep(5)
                continue
            listen(dev)
        except OSError:  # receiver unplugged or read failed
            emit(None)
            time.sleep(2)
        finally:
            if dev is not None:
                dev.close()


if __name__ == "__main__":
    main()
