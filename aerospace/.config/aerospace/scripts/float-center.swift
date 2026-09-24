// Resize the focused window of <pid> to <ratio> of NSScreen.screens[<screen> - 1]
// and centre it on that screen.
//
// Compiled on demand by float-center.sh, which is where the AeroSpace binding
// is documented. Talking to the Accessibility API directly rather than through
// System Events is what keeps the shortcut under ~100ms.

import AppKit

let args = CommandLine.arguments
guard args.count == 4,
      let pid = pid_t(args[1]),
      let screenNumber = Int(args[2]),
      let ratio = Double(args[3]) else {
    FileHandle.standardError.write(Data("usage: float-center <pid> <screen> <ratio>\n".utf8))
    exit(2)
}

// AeroSpace reports a window's monitor as a 1-based index into NSScreen.screens.
let screens = NSScreen.screens
guard let primary = screens.first else { exit(1) }
let screen = screens.indices.contains(screenNumber - 1) ? screens[screenNumber - 1] : primary

// The Accessibility API is top-left origin, anchored to the primary screen;
// AppKit frames are bottom-left origin.
func axTop(_ rect: NSRect) -> CGFloat { primary.frame.maxY - rect.maxY }

func clamp(_ value: CGFloat, _ lower: CGFloat, _ upper: CGFloat) -> CGFloat {
    min(max(value, lower), upper)
}

let full = screen.frame
let visible = screen.visibleFrame

// A fraction of the whole screen, centred on the whole screen: the gaps above
// and below the window have to look equal, so the menu bar must not push it
// down. Never larger than the usable area, though.
let width = min((full.width * ratio).rounded(), visible.width)
let height = min((full.height * ratio).rounded(), visible.height)

// Nudge back inside the usable area if a large ratio or a pinned Dock would
// otherwise leave part of the window unreachable.
var origin = CGPoint(
    x: clamp((full.minX + (full.width - width) / 2).rounded(),
             visible.minX, visible.maxX - width),
    y: clamp((axTop(full) + (full.height - height) / 2).rounded(),
             axTop(visible), axTop(visible) + visible.height - height)
)
var size = CGSize(width: width, height: height)

var focused: CFTypeRef?
guard AXUIElementCopyAttributeValue(
          AXUIElementCreateApplication(pid),
          kAXFocusedWindowAttribute as CFString,
          &focused
      ) == .success,
      let element = focused, CFGetTypeID(element) == AXUIElementGetTypeID() else { exit(1) }
let window = element as! AXUIElement

func set(_ attribute: String, _ value: AXValue?) {
    guard let value else { return }
    AXUIElementSetAttributeValue(window, attribute as CFString, value)
}

// Apps that clamp their own geometry can ignore the first move, so position,
// resize, then position again.
set(kAXPositionAttribute, AXValueCreate(.cgPoint, &origin))
set(kAXSizeAttribute, AXValueCreate(.cgSize, &size))
set(kAXPositionAttribute, AXValueCreate(.cgPoint, &origin))
