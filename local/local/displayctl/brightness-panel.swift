// brightness-panel: a small popover with a brightness slider per external
// monitor. The SwiftBar plugin opens it from its menu, so it appears just below
// the mouse pointer, and it closes on Esc or a click anywhere else.
//
// Brightness is read and set through displayctl (installed next to this
// binary), which keeps the DDC code in one place.

import AppKit
import SwiftUI

let displayctl = Bundle.main.executableURL!.resolvingSymlinksInPath()
    .deletingLastPathComponent().appendingPathComponent("displayctl")

/// Runs displayctl off the main thread; nil if it failed.
func displayctl(_ arguments: [String]) async -> String? {
    await withCheckedContinuation { continuation in
        DispatchQueue.global().async {
            let process = Process()
            let output = Pipe()
            process.executableURL = displayctl
            process.arguments = arguments
            process.standardOutput = output
            process.standardError = FileHandle.nullDevice
            guard (try? process.run()) != nil else { return continuation.resume(returning: nil) }
            let data = output.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            continuation.resume(returning: process.terminationStatus == 0 ? String(decoding: data, as: UTF8.self) : nil)
        }
    }
}

@MainActor
final class Monitor: ObservableObject, Identifiable {
    let id: String  // displayctl selector
    let name: String
    @Published var brightness: Double
    @Published var failed = false
    private var touched = false
    private var pending: Int?
    private(set) var busy = false

    init(selector: String, name: String, cached: Double?) {
        id = selector
        self.name = name
        brightness = cached ?? 100
    }

    /// The cached value from displayctl may be stale if the monitor's own
    /// buttons were used, so ask the monitor once the panel is up.
    func refresh() async {
        let output = await displayctl(["brightness", id])
        guard !touched else { return }
        if let value = output.flatMap({ Double($0.trimmingCharacters(in: .whitespacesAndNewlines).dropLast()) }) {
            brightness = value
        } else {
            failed = true
        }
    }

    /// One displayctl at a time per monitor: while one runs, newer values
    /// replace each other, so dragging never queues up stale levels.
    func send(_ value: Int) {
        touched = true
        pending = value
        guard !busy else { return }
        busy = true
        Task {
            while let value = pending {
                pending = nil
                failed = await displayctl(["brightness", id, String(value)]) == nil
            }
            busy = false
        }
    }
}

/// Active displays from 'displayctl list --tsv'.
@MainActor
func loadMonitors() async -> [Monitor] {
    guard let output = await displayctl(["list", "--tsv"]) else { return [] }
    return output.split(separator: "\n").dropFirst().compactMap { line in
        let columns = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
        guard columns.count == 11, columns[5].hasPrefix("active") else { return nil }
        return Monitor(selector: columns[10], name: columns[7], cached: Double(columns[8].dropLast()))
    }
}

struct MonitorRow: View {
    @ObservedObject var monitor: Monitor

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "display")
                Text(monitor.name).font(.headline)
                Spacer()
                if monitor.failed {
                    Text("DDC failed").foregroundStyle(.red)
                } else {
                    Text("\(Int(monitor.brightness))%").monospacedDigit().foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 8) {
                Image(systemName: "sun.min").foregroundStyle(.secondary)
                Slider(value: Binding(get: { monitor.brightness }, set: { value in
                    let level = value.rounded()
                    guard level != monitor.brightness else { return }
                    monitor.brightness = level
                    monitor.send(Int(level))
                }), in: 0...100)
                Image(systemName: "sun.max").foregroundStyle(.secondary)
            }
        }
    }
}

struct PanelView: View {
    let monitors: [Monitor]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if monitors.isEmpty {
                Text("No external displays").foregroundStyle(.secondary)
            }
            ForEach(monitors) { MonitorRow(monitor: $0) }
        }
        .padding(20)
        .frame(width: 360)
    }
}

/// A title-bar-less panel that can still take keyboard focus, for Esc.
final class Popover: NSPanel {
    override var canBecomeKey: Bool { true }
    override func cancelOperation(_ sender: Any?) { Task { await dismiss(monitors: monitors) } }
    var monitors: [Monitor] = []
}

/// Hide at once, but let the last brightness change reach the monitor before quitting.
@MainActor
func dismiss(monitors: [Monitor]) async {
    NSApp.windows.forEach { $0.orderOut(nil) }
    while monitors.contains(where: \.busy) {
        try? await Task.sleep(for: .milliseconds(50))
    }
    NSApp.terminate(nil)
}

final class Delegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var monitors: [Monitor] = []
    func windowDidResignKey(_ notification: Notification) {
        Task { @MainActor in await dismiss(monitors: monitors) }
    }
}

@MainActor
func showPanel() async {
    let monitors = await loadMonitors()
    let hosting = NSHostingView(rootView: PanelView(monitors: monitors))
    hosting.frame.size = hosting.fittingSize
    let background = NSVisualEffectView(frame: hosting.frame)
    background.material = .popover
    background.state = .active
    background.addSubview(hosting)

    let panel = Popover(contentRect: hosting.frame, styleMask: [.titled, .fullSizeContentView],
                        backing: .buffered, defer: false)
    panel.monitors = monitors
    panel.titlebarAppearsTransparent = true
    panel.titleVisibility = .hidden
    [.closeButton, .miniaturizeButton, .zoomButton].forEach { panel.standardWindowButton($0)?.isHidden = true }
    panel.contentView = background
    panel.level = .popUpMenu
    delegate.monitors = monitors
    panel.delegate = delegate

    // Top-centred on the pointer, kept inside the visible part of its screen.
    let mouse = NSEvent.mouseLocation
    let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main!
    let visible = screen.visibleFrame
    let size = panel.frame.size
    panel.setFrameOrigin(NSPoint(x: min(max(mouse.x - size.width / 2, visible.minX + 8), visible.maxX - size.width - 8),
                                 y: min(max(mouse.y - size.height + 8, visible.minY + 8), visible.maxY - size.height)))
    panel.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)

    // Launched from SwiftBar the panel may not get focus, in which case it never
    // resigns it either; a click outside closes it regardless.
    NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { _ in
        Task { @MainActor in await dismiss(monitors: monitors) }
    }

    for monitor in monitors {
        Task { await monitor.refresh() }
    }
}

let app = NSApplication.shared
let delegate = Delegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
Task { @MainActor in await showPanel() }
app.run()
