// displayctl: disconnect and reconnect a display the way unplugging it would,
// without third-party tools. See README.md next to this file.
//
// The mechanism is the private CoreGraphics call CGSConfigureDisplayEnabled,
// run inside a normal display configuration transaction completed with
// .forSession, so logging out or rebooting brings every display back.
//
// A disabled display vanishes from CGGetOnlineDisplayList entirely, so the
// only way back is the display ID saved before it was disabled. Targets are
// kept in ~/.config/displayctl/targets.json for that reason.

import AppKit
import ColorSync
import CoreGraphics
import Foundation

// MARK: - Errors and output

struct Failure: Error {
    let message: String
    let code: Int32
}

func fail(_ message: String, code: Int32 = 2) -> Failure { Failure(message: message, code: code) }

func hex(_ value: UInt32) -> String { String(format: "0x%04x", value) }

// MARK: - Private API

typealias ConfigureEnabledFn = @convention(c) (CGDisplayConfigRef?, CGDirectDisplayID, Bool) -> CGError

// Looked up at runtime rather than declared with @_silgen_name: the latter uses
// the Swift calling convention, and a macOS update that drops the symbol would
// then stop the binary from launching at all instead of producing an error.
func configureEnabled() throws -> ConfigureEnabledFn {
    guard let handle = dlopen("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics", RTLD_NOW),
          let symbol = dlsym(handle, "CGSConfigureDisplayEnabled") else {
        throw fail("CGSConfigureDisplayEnabled is not available on this macOS version")
    }
    return unsafeBitCast(symbol, to: ConfigureEnabledFn.self)
}

func setEnabled(_ id: CGDirectDisplayID, _ enabled: Bool) throws {
    let configure = try configureEnabled()
    var config: CGDisplayConfigRef?
    let begun = CGBeginDisplayConfiguration(&config)
    guard begun == .success else { throw fail("CGBeginDisplayConfiguration failed (\(begun.rawValue))") }
    let err = configure(config, id, enabled)
    guard err == .success else {
        CGCancelDisplayConfiguration(config)
        throw fail("CGSConfigureDisplayEnabled(\(id), \(enabled)) failed (\(err.rawValue))", code: 1)
    }
    let done = CGCompleteDisplayConfiguration(config, .forSession)
    guard done == .success else { throw fail("CGCompleteDisplayConfiguration failed (\(done.rawValue))", code: 1) }
}

// MARK: - Displays

struct Display {
    let id: CGDirectDisplayID
    let vendor: UInt32
    let model: UInt32
    let serial: UInt32
    let uuid: String
    let builtin: Bool
    let active: Bool
    let asleep: Bool
    let main: Bool

    init(_ id: CGDirectDisplayID) {
        self.id = id
        vendor = CGDisplayVendorNumber(id)
        model = CGDisplayModelNumber(id)
        serial = CGDisplaySerialNumber(id)
        uuid = CGDisplayCreateUUIDFromDisplayID(id).map {
            CFUUIDCreateString(nil, $0.takeRetainedValue()) as String
        } ?? ""
        builtin = CGDisplayIsBuiltin(id) != 0
        active = CGDisplayIsActive(id) != 0
        asleep = CGDisplayIsAsleep(id) != 0
        main = CGDisplayIsMain(id) != 0
    }
}

func displayIDs(_ get: (UInt32, UnsafeMutablePointer<CGDirectDisplayID>?, UnsafeMutablePointer<UInt32>?) -> CGError) -> [CGDirectDisplayID] {
    var count: UInt32 = 0
    var ids = [CGDirectDisplayID](repeating: 0, count: 32)
    guard get(UInt32(ids.count), &ids, &count) == .success else { return [] }
    return Array(ids.prefix(Int(count)))
}

func onlineDisplays() -> [Display] { displayIDs(CGGetOnlineDisplayList).map(Display.init) }
func activeIDs() -> [CGDirectDisplayID] { displayIDs(CGGetActiveDisplayList) }

// Only active screens have an NSScreen, so asleep or mirrored displays fall
// back to whatever name was saved for them.
@MainActor
func screenNames() -> [CGDirectDisplayID: String] {
    var names: [CGDirectDisplayID: String] = [:]
    for screen in NSScreen.screens {
        if let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
            names[number.uint32Value] = screen.localizedName
        }
    }
    return names
}

// Display reconfiguration is asynchronous; give WindowServer a moment to settle.
func waitUntil(timeout: TimeInterval = 5, _ condition: () -> Bool) -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
        if condition() { return true }
        Thread.sleep(forTimeInterval: 0.25)
    }
    return condition()
}

// The disabled state only lasts until reboot, so a saved "disabled" flag is
// only believed if it was written during the current boot.
func bootTime() -> Int {
    var boot = timeval()
    var size = MemoryLayout<timeval>.size
    sysctlbyname("kern.boottime", &boot, &size, nil, 0)
    return boot.tv_sec
}

// MARK: - Saved targets

struct Target: Codable {
    var vendor: UInt32
    var model: UInt32
    var serial: UInt32
    var uuid: String
    var lastDisplayID: CGDirectDisplayID
    var name: String?
    var disabledDuringBoot: Int?

    init(_ display: Display) {
        vendor = display.vendor
        model = display.model
        serial = display.serial
        uuid = display.uuid
        lastDisplayID = display.id
    }

    // Vendor, model and serial come from the monitor itself; the UUID can change
    // with the port it is plugged into, so it is only the fallback.
    func matches(_ display: Display) -> Bool {
        if vendor == display.vendor && model == display.model { return serial == 0 || serial == display.serial }
        return !uuid.isEmpty && uuid == display.uuid
    }

    var disabledByUs: Bool { disabledDuringBoot == bootTime() }
}

struct Store {
    static let url = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".config/displayctl/targets.json")

    var targets: [String: Target]
    private var original: Data?

    init() throws {
        original = try? Data(contentsOf: Store.url)
        guard let data = original else { targets = [:]; return }
        do {
            targets = try JSONDecoder().decode([String: Target].self, from: data)
        } catch {
            throw fail("cannot read \(Store.url.path): \(error.localizedDescription)")
        }
    }

    // Written only when something changed, since the SwiftBar plugin lists
    // the displays every few seconds.
    func save() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(targets)
        guard data != original else { return }
        try FileManager.default.createDirectory(at: Store.url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: Store.url, options: .atomic)
    }

    func alias(for display: Display) -> String? {
        targets.filter { $0.value.matches(display) }.keys.sorted().first
    }
}

// MARK: - Selectors

enum Selector {
    case alias(String)
    case uuid(String)
    case hardware(vendor: UInt32, model: UInt32, serial: UInt32?)
    case displayID(CGDirectDisplayID)

    init(_ text: String) throws {
        let parts = text.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
        func hexNumber(_ s: String) -> UInt32? {
            UInt32(s.lowercased().hasPrefix("0x") ? String(s.dropFirst(2)) : s, radix: 16)
        }
        if UUID(uuidString: text) != nil {
            self = .uuid(text.uppercased())
        } else if let id = UInt32(text) {
            self = .displayID(id)
        } else if (2...3).contains(parts.count), let vendor = hexNumber(parts[0]), let model = hexNumber(parts[1]) {
            var serial: UInt32?
            if parts.count == 3 {
                guard let s = UInt32(parts[2]) else { throw fail("bad serial in '\(text)' (expected decimal, as shown by 'displayctl list')") }
                serial = s
            }
            self = .hardware(vendor: vendor, model: model, serial: serial)
        } else if text.first?.isLetter == true && !text.contains(":") {
            self = .alias(text)
        } else {
            throw fail("bad selector '\(text)' (expected an alias, a UUID, vendor:model[:serial] in hex, or a display ID)")
        }
    }

    func matches(_ display: Display) -> Bool {
        switch self {
        case .alias: return false
        case .uuid(let uuid): return display.uuid == uuid
        case .hardware(let vendor, let model, let serial):
            return display.vendor == vendor && display.model == model && (serial == nil || display.serial == serial)
        case .displayID(let id): return display.id == id
        }
    }

    func matches(_ target: Target) -> Bool {
        switch self {
        case .alias: return false
        case .uuid(let uuid): return target.uuid == uuid
        case .hardware(let vendor, let model, let serial):
            return target.vendor == vendor && target.model == model && (serial == nil || target.serial == serial)
        case .displayID(let id): return target.lastDisplayID == id
        }
    }

    // Saved targets need a name even when no alias was given, so a display
    // disconnected by UUID or hardware IDs can still be reconnected.
    static func defaultKey(for display: Display) -> String {
        String(format: "%04x:%04x:%u", display.vendor, display.model, display.serial)
    }
}

/// What a selector currently refers to: the online display it matches (if
/// any), and the saved target that remembers it (if any).
struct Resolved {
    var key: String?
    var display: Display?
    var target: Target?
}

func resolve(_ text: String, in store: Store) throws -> Resolved {
    let selector = try Selector(text)
    let online = onlineDisplays()

    if case .alias(let name) = selector {
        guard let target = store.targets[name] else {
            throw fail("unknown alias '\(name)'; create it with 'displayctl alias \(name) <selector>'")
        }
        let matches = online.filter(target.matches)
        guard matches.count <= 1 else {
            throw fail("alias '\(name)' matches several displays (\(matches.map { String($0.id) }.joined(separator: ", "))); re-create it with a serial or UUID")
        }
        return Resolved(key: name, display: matches.first, target: target)
    }

    let matches = online.filter(selector.matches)
    guard matches.count <= 1 else {
        throw fail("'\(text)' matches several displays (\(matches.map { String($0.id) }.joined(separator: ", "))); add the serial or use the UUID")
    }
    if let display = matches.first {
        let key = store.alias(for: display) ?? Selector.defaultKey(for: display)
        return Resolved(key: key, display: display, target: store.targets[key])
    }
    let saved = store.targets.filter { selector.matches($0.value) }
    guard saved.count <= 1 else {
        throw fail("'\(text)' matches several saved targets (\(saved.keys.sorted().joined(separator: ", "))); use an alias")
    }
    return Resolved(key: saved.first?.key, display: nil, target: saved.first?.value)
}

/// Remember an online display's current identifiers under its key. Its name
/// is kept, because asleep or mirrored displays have no NSScreen to ask.
@MainActor
func remember(_ display: Display, as key: String, in store: inout Store) {
    var target = Target(display)
    target.name = store.targets[key]?.name ?? screenNames()[display.id]
    store.targets[key] = target
}

// MARK: - Commands

/// `tsv` is for scripts such as the SwiftBar plugin: tab-separated, with an
/// extra SELECTOR column that keeps working after the display is disabled.
@MainActor
func list(tsv: Bool) throws {
    var store = try Store()
    let online = onlineDisplays()
    let names = screenNames()
    var rows: [[String]] = [["ID", "VENDOR", "MODEL", "SERIAL", "BUILTIN", "STATE", "ALIAS", "NAME", "UUID", "SELECTOR"]]

    for display in online {
        let alias = store.alias(for: display)
        if let alias { remember(display, as: alias, in: &store) }
        let state = display.active ? (display.main ? "active,main" : "active")
            : display.asleep ? "asleep" : "mirrored"
        let name = names[display.id] ?? alias.flatMap { store.targets[$0]?.name } ?? "-"
        rows.append([String(display.id), hex(display.vendor), hex(display.model), String(display.serial),
                     display.builtin ? "yes" : "no", state, alias ?? "-", name, display.uuid,
                     alias ?? Selector.defaultKey(for: display)])
    }
    // Saved targets that are not online are either disabled by displayctl or
    // physically gone; the IDs shown are the last ones seen.
    for (key, target) in store.targets.sorted(by: { $0.key < $1.key }) where !online.contains(where: target.matches) {
        let state = target.disabledByUs ? "disabled" : "offline"
        rows.append([String(target.lastDisplayID), hex(target.vendor), hex(target.model), String(target.serial),
                     "-", state, key, target.name ?? "-", target.uuid, key])
    }
    try store.save()

    if tsv {
        rows.forEach { print($0.joined(separator: "\t")) }
        return
    }
    rows = rows.map { Array($0.dropLast()) }
    let widths = rows[0].indices.map { column in rows.map { $0[column].count }.max() ?? 0 }
    for row in rows {
        print(zip(row, widths).map { $0.padding(toLength: $1, withPad: " ", startingAt: 0) }
            .joined(separator: "  ").trimmingCharacters(in: .whitespaces))
    }
}

@MainActor
func status(_ selector: String) throws -> Int32 {
    var store = try Store()
    let resolved = try resolve(selector, in: store)
    guard let display = resolved.display else {
        guard resolved.target != nil else { throw fail("no display matches '\(selector)'") }
        print("disconnected")
        return 1
    }
    if let key = resolved.key, resolved.target != nil { remember(display, as: key, in: &store) }
    try store.save()
    print("connected")
    return 0
}

@MainActor
func disconnect(_ selector: String, force: Bool) throws {
    var store = try Store()
    let resolved = try resolve(selector, in: store)
    guard let display = resolved.display, let key = resolved.key else {
        print("already disconnected")
        return
    }
    if display.builtin && !force {
        throw fail("refusing to disconnect the built-in display \(display.id) without --force")
    }
    // Never leave the Mac without a screen, --force or not.
    guard activeIDs().contains(where: { $0 != display.id }) else {
        throw fail("refusing to disconnect display \(display.id): it is the only active display")
    }

    // Save the ID before disabling: once disabled the display can't be enumerated.
    remember(display, as: key, in: &store)
    try store.save()

    try setEnabled(display.id, false)
    guard waitUntil({ !displayIDs(CGGetOnlineDisplayList).contains(display.id) }) else {
        throw fail("display \(display.id) is still online after disabling it", code: 1)
    }
    store.targets[key]?.disabledDuringBoot = bootTime()
    try store.save()
    print("disconnected display \(display.id) (\(key)); reconnect with 'displayctl connect \(key)'")
}

@MainActor
func connect(_ selector: String) throws {
    var store = try Store()
    let resolved = try resolve(selector, in: store)
    if let display = resolved.display, let key = resolved.key {
        if resolved.target != nil { remember(display, as: key, in: &store) }
        try store.save()
        print("already connected")
        return
    }
    guard let key = resolved.key, let target = resolved.target else {
        throw fail("no saved display matches '\(selector)'; it must be seen connected once (any displayctl command does that)")
    }

    let id = target.lastDisplayID
    // Should never happen, but don't toggle some other display that now has this ID.
    if let other = onlineDisplays().first(where: { $0.id == id }), !target.matches(other) {
        throw fail("saved display ID \(id) now belongs to another display; can't reconnect '\(key)'")
    }

    let enableError = Result { try setEnabled(id, true) }
    guard waitUntil({ onlineDisplays().contains(where: target.matches) }) else {
        var reason = "display \(id) (\(key)) did not come back"
        if case .failure(let error as Failure) = enableError { reason += ": \(error.message)" }
        if !target.disabledByUs { reason += "; it was not disabled by displayctl since boot, so it is probably unplugged or the KVM is switched away" }
        throw fail(reason, code: 1)
    }
    if let display = onlineDisplays().first(where: target.matches) {
        remember(display, as: key, in: &store)
    }
    try store.save()
    print("connected display \(id) (\(key))")
}

@MainActor
func alias(_ name: String, _ selector: String) throws {
    guard name.first?.isLetter == true, !name.contains(":") else {
        throw fail("alias names must start with a letter and contain no ':'")
    }
    var store = try Store()
    let resolved = try resolve(selector, in: store)
    guard let display = resolved.display else {
        throw fail("'\(selector)' does not match a connected display; connect it first")
    }
    // Drop the automatic entry if this display was saved under one before.
    let automatic = Selector.defaultKey(for: display)
    if automatic != name { store.targets.removeValue(forKey: automatic) }
    remember(display, as: name, in: &store)
    try store.save()
    print("'\(name)' -> display \(display.id), vendor \(hex(display.vendor)) model \(hex(display.model)) serial \(display.serial)")
}

let usage = """
    usage: displayctl list [--tsv]
           displayctl status <selector>         prints connected/disconnected; exit 0/1, 2 on error
           displayctl disconnect <selector> [--force]
           displayctl connect <selector>
           displayctl alias <name> <selector>   save a display under a friendly name

    selector: an alias, a UUID, vendor:model[:serial] (vendor and model in hex,
    serial in decimal, as shown by 'displayctl list'), or a display ID.
    Targets are saved in ~/.config/displayctl/targets.json.
    """

// MARK: - Main

@MainActor
func run(_ arguments: [String]) -> Int32 {
    var args = arguments
    let force = args.contains("--force")
    let tsv = args.contains("--tsv")
    args.removeAll { $0 == "--force" || $0 == "--tsv" }

    do {
        switch (args.first, args.count) {
        case ("list", 1): try list(tsv: tsv)
        case ("status", 2): return try status(args[1])
        case ("disconnect", 2): try disconnect(args[1], force: force)
        case ("connect", 2): try connect(args[1])
        case ("alias", 3): try alias(args[1], args[2])
        case ("help", _), ("-h", _), ("--help", _): print(usage)
        default:
            FileHandle.standardError.write(Data((usage + "\n").utf8))
            return 2
        }
        return 0
    } catch let failure as Failure {
        FileHandle.standardError.write(Data("displayctl: \(failure.message)\n".utf8))
        return failure.code
    } catch {
        FileHandle.standardError.write(Data("displayctl: \(error.localizedDescription)\n".utf8))
        return 2
    }
}

exit(MainActor.assumeIsolated { run(Array(CommandLine.arguments.dropFirst())) })
