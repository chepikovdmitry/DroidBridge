import Darwin
import DroidBridgeMTP
import Foundation

private let usage = """
Usage: droidbridge-usb COMMAND
  devices                        Detect connected MTP devices
  storages                       List storages on the phone
  ls STORAGE [FOLDER]            List a folder (defaults to root)
  pull OBJECT DESTINATION        Download one file without replacing a local file
  push SOURCE STORAGE FOLDER     Upload one file to the selected folder

IDs can be decimal or hexadecimal (0x...). Use root for the storage root.
Ctrl-C discards a download after USB transfer finishes. A started upload runs to completion.
"""

private struct UsageError: Error {
    let message: String
}

private enum Command {
    case help, devices, storages
    case list(storage: UInt32, folder: UInt32)
    case pull(object: UInt32, destination: URL)
    case push(source: URL, storage: UInt32, folder: UInt32)

    init(arguments: [String]) throws {
        switch arguments.first {
        case nil, "-h", "--help", "help":
            self = .help
        case "devices" where arguments.count == 1:
            self = .devices
        case "storages" where arguments.count == 1:
            self = .storages
        case "ls" where (2...3).contains(arguments.count):
            self = .list(
                storage: try Self.id(arguments[1], kind: "storage"),
                folder: try Self.folder(arguments.count == 3 ? arguments[2] : "root")
            )
        case "pull" where arguments.count == 3:
            self = .pull(
                object: try Self.id(arguments[1], kind: "object"),
                destination: URL(fileURLWithPath: arguments[2])
            )
        case "push" where arguments.count == 4:
            self = .push(
                source: URL(fileURLWithPath: arguments[1]),
                storage: try Self.id(arguments[2], kind: "storage"),
                folder: try Self.folder(arguments[3])
            )
        default:
            throw UsageError(message: "Unknown command or incorrect number of arguments.")
        }
    }

    func run() throws {
        if case .help = self {
            print(usage)
            return
        }
        try MTPSession.withDevices { devices in
            if case .devices = self {
                if devices.isEmpty { print(MTPSession.noDevice) }
                for device in devices {
                    let entry = device.device_entry
                    let vendor = entry.vendor.map { String(cString: $0) } ?? "Unknown vendor"
                    let product = entry.product.map { String(cString: $0) } ?? "Unknown device"
                    let usbID = String(format: "%04x:%04x", Int(entry.vendor_id), Int(entry.product_id))
                    print("\(usbID)  \(vendor) \(product)")
                }
                return
            }
            guard let raw = devices.baseAddress, !devices.isEmpty else { throw USBError(MTPSession.noDevice) }
            guard devices.count == 1 else { throw USBError("Connect one MTP device at a time.") }
            let session = try MTPSession(rawDevice: raw)
            try run(in: session)
        }
    }

    private func run(in session: MTPSession) throws {
        switch self {
        case .storages:
            let storages = try session.storages()
            if storages.isEmpty { throw USBError("No MTP storage is visible. Unlock your phone and allow file access.") }
            for storage in storages {
                let free = storage.freeBytes == UInt64.max ? "unknown free space" : "\(storage.freeBytes) bytes free"
                print("\(storage.id)\t\(storage.name.debugDescription)\t\(free)")
            }
        case .list(let storage, let folder):
            for entry in try session.entries(storage: storage, folder: folder) {
                let kind = entry.isFolder ? "folder" : "file"
                let size = entry.isFolder ? "-" : String(entry.size)
                print("\(entry.id)\t\(kind)\t\(size)\t\(entry.name.debugDescription)")
            }
        case .pull(let object, let destination):
            do {
                try withTransferProgress(discardOnCancellation: true) { report, cancellation in
                    try session.pull(object: object, to: destination, progress: report, discard: cancellation)
                }
            } catch is CancellationError {
                throw USBError("Download cancelled.")
            }
            print("Downloaded to \(destination.path.debugDescription)")
        case .push(let source, let storage, let folder):
            let id = try withTransferProgress { report, _ in
                try session.push(source: source, storage: storage, folder: folder, progress: report)
            }
            print("Uploaded object \(id)")
        case .help, .devices:
            break
        }
    }

    private static func folder(_ value: String) throws -> UInt32 {
        if value == "root" { return MTPSession.root }
        return try id(value, kind: "folder")
    }

    private static func id(_ value: String, kind: String) throws -> UInt32 {
        let isHex = value.lowercased().hasPrefix("0x")
        let digits = isHex ? value.dropFirst(2) : value[...]
        let allowed = isHex ? "0123456789abcdefABCDEF" : "0123456789"
        guard digits.allSatisfy({ allowed.contains($0) }),
              let id = UInt32(digits, radix: isHex ? 16 : 10),
              id != 0, id != UInt32.max else {
            throw UsageError(message: "Invalid \(kind) ID: \(value.debugDescription).")
        }
        return id
    }
}

do {
    try Command(arguments: Array(CommandLine.arguments.dropFirst())).run()
} catch let error as UsageError {
    writeError("\(error.message)\n\n\(usage)\n")
    exit(2)
} catch {
    writeError("\(error.localizedDescription)\n")
    exit(1)
}
