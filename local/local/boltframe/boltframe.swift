// boltframe: a red border, a faint red wash and a label over every display,
// started by the Bolt SwiftBar plugin when the keyboard leaves this Mac, so
// it's obvious that typing on it goes nowhere here. It goes away when the
// plugin sends SIGTERM (the keyboard came back) or when a key is pressed here:
// that must be another keyboard, such as the built-in one with the lid open,
// so you're working here on purpose. It also exits if the plugin dies, so it
// can't outlive it. Clicks pass through: the mouse may still be here.
//
// Key presses are detected by polling the system idle time, which needs no
// Accessibility or Input Monitoring permission.

import AppKit

let label = "Keyboard isn't connected to this Mac"
let border: CGFloat = 6
let grace: TimeInterval = 0.5  // keys still in flight from the keyboard that just left

final class OverlayView: NSView {
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer!.backgroundColor = NSColor.systemRed.withAlphaComponent(0.15).cgColor

        let band = CAShapeLayer()
        let path = CGMutablePath()
        path.addRect(bounds)
        path.addRect(bounds.insetBy(dx: border, dy: border))
        band.path = path
        band.fillRule = .evenOdd
        band.fillColor = NSColor.systemRed.withAlphaComponent(0.85).cgColor
        layer!.addSublayer(band)

        // The label sits on a dark pill so it reads over any background.
        let text = NSTextField(labelWithString: label)
        text.font = .systemFont(ofSize: 28, weight: .semibold)
        text.textColor = .white
        let pill = NSView()
        pill.wantsLayer = true
        pill.layer!.backgroundColor = NSColor.black.withAlphaComponent(0.6).cgColor
        pill.layer!.cornerRadius = 16
        pill.addSubview(text)
        addSubview(pill)

        text.translatesAutoresizingMaskIntoConstraints = false
        pill.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            text.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 28),
            text.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -28),
            text.topAnchor.constraint(equalTo: pill.topAnchor, constant: 16),
            text.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -16),
            pill.centerXAnchor.constraint(equalTo: centerXAnchor),
            pill.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("not used") }
}

guard CommandLine.arguments.count == 1 else {
    FileHandle.standardError.write("usage: boltframe\n".data(using: .utf8)!)
    exit(2)
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)  // no Dock icon, never takes focus

@MainActor var windows: [NSWindow] = []

/// One click-through window per display, above everything including full-screen apps.
@MainActor func showOverlays() {
    windows.forEach { $0.orderOut(nil) }
    windows = NSScreen.screens.map { screen in
        let window = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        window.contentView = OverlayView(frame: NSRect(origin: .zero, size: screen.frame.size))
        window.orderFrontRegardless()
        return window
    }
}

MainActor.assumeIsolated { showOverlays() }  // top-level code runs on the main thread
// Displays come and go (KVM, displayctl, the lid): redraw on every change.
NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
                                       object: nil, queue: .main) { _ in MainActor.assumeIsolated { showOverlays() } }

let parent = getppid()
let shown = Date()
Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
    if getppid() != parent {
        exit(0)  // the plugin died and can't take the overlay down any more
    }
    let elapsed = -shown.timeIntervalSinceNow
    if elapsed > grace && CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .keyDown) < elapsed - grace {
        exit(0)  // typed on another keyboard here
    }
}
app.run()
