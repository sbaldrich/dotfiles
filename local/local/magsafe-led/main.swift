import Darwin
import Foundation
import IOKit
import IOKit.pwr_mgt
import IOKit.ps

// Minimal foreground enforcement. No files, socket, launchd registration, or network.
final class LEDKeeper {
    private var rootPort: io_connect_t = 0
    private var notificationPort: IONotificationPortRef?
    private var notifier: io_object_t = 0
    private var signalSources: [DispatchSourceSignal] = []
    private var timer: Timer?
    private var powerSource: CFRunLoopSource?
    private var lastError: String?

    func run() -> Bool {
        // Register before settling into the run loop so the LED is written
        // before acknowledging system sleep, then reasserted after wake.
        let callback: IOServiceInterestCallback = { context, _, message, argument in
            guard let context else { return }
            let keeper = Unmanaged<LEDKeeper>.fromOpaque(context).takeUnretainedValue()
            switch message {
            case 0xe0000270: // kIOMessageCanSystemSleep
                IOAllowPowerChange(keeper.rootPort, Int(bitPattern: argument))
            case 0xe0000280: // kIOMessageSystemWillSleep
                keeper.reassert()
                IOAllowPowerChange(keeper.rootPort, Int(bitPattern: argument))
            case 0xe0000300: // kIOMessageSystemHasPoweredOn
                keeper.reassert()
            default:
                break
            }
        }
        let context = Unmanaged.passUnretained(self).toOpaque()
        rootPort = IORegisterForSystemPower(context, &notificationPort, callback, &notifier)
        guard rootPort != 0, let notificationPort,
              let runLoopSource = IONotificationPortGetRunLoopSource(notificationPort) else {
            return false
        }
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource.takeUnretainedValue(), .defaultMode)

        let powerCallback: IOPowerSourceCallbackType = { context in
            guard let context else { return }
            Unmanaged<LEDKeeper>.fromOpaque(context).takeUnretainedValue().reassert()
        }
        if let source = IOPSNotificationCreateRunLoopSource(powerCallback, context)?.takeRetainedValue() {
            powerSource = source
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
        }
        for signo in [SIGINT, SIGTERM, SIGHUP] {
            signal(signo, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: signo, queue: .main)
            source.setEventHandler { [weak self] in self?.restoreAndExit() }
            source.resume()
            signalSources.append(source)
        }
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            self?.reassert()
        }
        print("Keeping the LED off. Press Ctrl+C to restore macOS LED control.")
        RunLoop.main.run()
        return true
    }

    private func reassert() {
        do {
            try SMC.writeLED(off: true)
            lastError = nil
        } catch {
            let message = String(describing: error)
            if message != lastError {
                FileHandle.standardError.write(Data(("magsafe-led: " + message + "; will retry\n").utf8))
                lastError = message
            }
        }
    }

    private func restoreAndExit() {
        timer?.invalidate()
        do {
            try SMC.writeLED(off: false)
            print("LED returned to macOS control")
            exit(0)
        } catch {
            fail("Could not restore macOS LED control: \(error). Run magsafe-led on to retry")
        }
    }
}

let args = Array(CommandLine.arguments.dropFirst())
let usage = """
Usage: magsafe-led off [--keep] | on | --check | --help
  off       Turn the LED off (requires sudo).
  off --keep  Keep the LED off until Ctrl+C; restores macOS control on exit.
  on        Restore macOS charging-color control (requires sudo).
  --check   Query ACLC metadata without changing the LED.
  --help    Show this help without contacting the hardware.

One-shot settings may reset when macOS changes power state.
--keep runs in this terminal and reasserts off every 3 seconds and on power events.
Stop --keep with Ctrl+C before using on. It does not survive reboot or force-kill.
Requires Apple Silicon with MagSafe 3; the SMC interface is undocumented.
"""

func fail(_ message: String, code: Int32 = 1) -> Never {
    FileHandle.standardError.write(Data(("magsafe-led: " + message + "\n").utf8))
    exit(code)
}

if args == ["--help"] || args == ["-h"] {
    print(usage)
    exit(0)
}
let keepOff = args == ["off", "--keep"]
guard keepOff || (args.count == 1 && ["off", "on", "--check"].contains(args[0])) else {
    fail(usage, code: 64)
}
do {
    if args[0] == "--check" {
        let info = try SMC.checkLEDKey()
        print("ACLC: size=\(info.size), type=\(info.type)")
        guard info.supported else {
            fail("This ACLC key is not supported; no write was attempted")
        }
    } else {
        let off = args[0] == "off"
        try SMC.writeLED(off: off)
        print(off ? "LED off" : "LED returned to macOS control")
        if keepOff {
            let keeper = LEDKeeper()
            guard keeper.run() else {
                try SMC.writeLED(off: false)
                fail("Could not monitor system power; macOS LED control restored")
            }
        }
    }
} catch {
    fail(String(describing: error))
}
