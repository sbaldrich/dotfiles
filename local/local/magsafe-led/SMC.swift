// Adapted from MagSleep v1.3.7, Sources/MagSleepCore/SMC.swift
// (commit 89a52aba994cfc434409c8dbfbecc9150a2fe6f5). MIT license; see LICENSE.
import Darwin
import Foundation
import IOKit

/// Minimal AppleSMC client for the MagSafe LED key. The struct layout mirrors
/// the kernel's 80-byte SMCParamStruct, which AppleSMC reads via
/// IOConnectCallStructMethod, so every field below must stay.
enum SMC {
    enum SMCError: Error, CustomStringConvertible {
        case serviceNotFound
        case openFailed(kern_return_t)
        case callFailed(kern_return_t)
        case smcResult(UInt8)
        case unexpectedLayout(Int)
        case invalidReplySize(Int)
        case unsupportedLEDKey(UInt32, UInt32)
        case rootRequired

        var description: String {
            switch self {
            case .serviceNotFound: return "AppleSMC service not found"
            case .openFailed(let kr): return "IOServiceOpen failed (\(kr))"
            case .callFailed(let kr): return "IOConnectCallStructMethod failed (\(kr))"
            case .smcResult(let r):
                return r == 0x84
                    ? "SMC key not found (this Mac may not support the MagSafe LED)"
                    : "SMC returned error \(r)"
            case .unexpectedLayout(let size):
                return "SMCParamStruct has unexpected size \(size), refusing to talk to the SMC"
            case .invalidReplySize(let size):
                return "AppleSMC returned an unexpected reply size (\(size)); refusing to proceed"
            case .unsupportedLEDKey(let size, let type):
                return "ACLC is not a one-byte ui8 key (size=\(size), type=\(String(type, radix: 16))); refusing to write"
            case .rootRequired:
                return "LED writes require root; run this command with sudo"
            }
        }
    }

    struct SMCVersion {
        var major: UInt8 = 0
        var minor: UInt8 = 0
        var build: UInt8 = 0
        var reserved: UInt8 = 0
        var release: UInt16 = 0
    }

    struct SMCPLimitData {
        var version: UInt16 = 0
        var length: UInt16 = 0
        var cpuPLimit: UInt32 = 0
        var gpuPLimit: UInt32 = 0
        var memPLimit: UInt32 = 0
    }

    struct SMCKeyInfoData {
        var dataSize: UInt32 = 0
        var dataType: UInt32 = 0
        var dataAttributes: UInt8 = 0
    }

    // Fixed 32-byte kernel layout; must stay a single tuple of 32 UInt8.
    typealias SMCBytes = (
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8
    )

    struct SMCParamStruct {
        var key: UInt32 = 0
        var vers = SMCVersion()
        var pLimitData = SMCPLimitData()
        var keyInfo = SMCKeyInfoData()
        var padding: UInt16 = 0
        var result: UInt8 = 0
        var status: UInt8 = 0
        var data8: UInt8 = 0
        var data32: UInt32 = 0
        var bytes: SMCBytes = (
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        )
    }

    private static let kSMCHandleYPCEvent: UInt32 = 2
    private static let kSMCWriteKey: UInt8 = 6
    private static let kSMCGetKeyInfo: UInt8 = 9
    /// "ACLC" as a big-endian FourCC: the MagSafe LED control key.
    private static let ledKey: UInt32 = 0x41434c43
    /// "ui8 " as a big-endian FourCC.
    private static let typeUInt8: UInt32 = 0x75693820

    private static func withConnection<T>(_ body: (io_connect_t) throws -> T) throws -> T {
        guard MemoryLayout<SMCParamStruct>.stride == 80 else {
            throw SMCError.unexpectedLayout(MemoryLayout<SMCParamStruct>.stride)
        }
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        guard service != 0 else { throw SMCError.serviceNotFound }
        defer { IOObjectRelease(service) }

        var connection: io_connect_t = 0
        let kr = IOServiceOpen(service, mach_task_self_, 0, &connection)
        guard kr == kIOReturnSuccess else { throw SMCError.openFailed(kr) }
        defer { IOServiceClose(connection) }
        return try body(connection)
    }

    private static func call(_ connection: io_connect_t,
                             _ input: SMCParamStruct) throws -> SMCParamStruct {
        var input = input
        var output = SMCParamStruct()
        var outputSize = MemoryLayout<SMCParamStruct>.stride
        let kr = IOConnectCallStructMethod(
            connection,
            kSMCHandleYPCEvent,
            &input,
            MemoryLayout<SMCParamStruct>.stride,
            &output,
            &outputSize
        )
        guard kr == kIOReturnSuccess else { throw SMCError.callFailed(kr) }
        guard outputSize == MemoryLayout<SMCParamStruct>.stride else {
            throw SMCError.invalidReplySize(outputSize)
        }
        guard output.result == 0 else { throw SMCError.smcResult(output.result) }
        return output
    }

    private static func ledKeyInfo(_ connection: io_connect_t) throws -> SMCKeyInfoData {
        var request = SMCParamStruct()
        request.key = ledKey
        request.data8 = kSMCGetKeyInfo
        return try call(connection, request).keyInfo
    }

    /// Reads ACLC's size and type without changing anything (no root needed).
    static func checkLEDKey() throws -> (size: UInt32, type: String, supported: Bool) {
        try withConnection { connection in
            let info = try ledKeyInfo(connection)
            let type = String(
                bytes: (0..<4).map { UInt8(info.dataType >> UInt32(24 - 8 * $0) & 0xff) },
                encoding: .ascii
            ) ?? "????"
            return (info.dataSize, type, info.dataSize == 1 && info.dataType == typeUInt8)
        }
    }

    /// Writes ACLC: off = true turns the LED off, false returns it to macOS.
    static func writeLED(off: Bool) throws {
        guard geteuid() == 0 else { throw SMCError.rootRequired }
        try withConnection { connection in
            let info = try ledKeyInfo(connection)
            guard info.dataSize == 1, info.dataType == typeUInt8 else {
                throw SMCError.unsupportedLEDKey(info.dataSize, info.dataType)
            }
            var request = SMCParamStruct()
            request.key = ledKey
            request.data8 = kSMCWriteKey
            request.keyInfo.dataSize = info.dataSize
            request.bytes.0 = off ? 1 : 0
            _ = try call(connection, request)
        }
    }
}
