import Foundation

// Dev-only: verifies the Swift struct matches the AppleSMC kernel layout
// without touching any hardware. Build: see README.
@main
enum OfflineChecks {
    static func main() {
        typealias P = SMC.SMCParamStruct
        precondition(MemoryLayout<P>.stride == 80)
        precondition(MemoryLayout<P>.offset(of: \.key) == 0)
        precondition(MemoryLayout<P>.offset(of: \.keyInfo) == 28)
        precondition(MemoryLayout<P>.offset(of: \.result) == 40)
        precondition(MemoryLayout<P>.offset(of: \.status) == 41)
        precondition(MemoryLayout<P>.offset(of: \.data8) == 42)
        precondition(MemoryLayout<P>.offset(of: \.data32) == 44)
        precondition(MemoryLayout<P>.offset(of: \.bytes) == 48)
        print("SMC ABI layout checks passed; no hardware access.")
    }
}
