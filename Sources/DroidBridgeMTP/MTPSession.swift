import CLibMTP
import Darwin
import DroidBridgeCore
import Foundation

package struct USBError: LocalizedError {
    package let errorDescription: String?

    package init(_ message: String) {
        errorDescription = message
    }
}

package final class MTPSession {
    package struct Entry: Sendable, Equatable {
        package let id: UInt32
        package let name: String
        package let size: UInt64
        package let isFolder: Bool
        package let modifiedAt: Date?
    }

    package static let root = UInt32.max
    package static let noDevice = L10n.text("No MTP device found. Unlock your Android phone and select File transfer over USB.")
    private let device: UnsafeMutablePointer<LIBMTP_mtpdevice_t>

    private static let initialized: Void = { LIBMTP_Init() }()

    package static func withDevices<Result>(
        _ run: (UnsafeMutableBufferPointer<LIBMTP_raw_device_t>) throws -> Result
    ) throws -> Result {
        _ = initialized
        var devices: UnsafeMutablePointer<LIBMTP_raw_device_t>?
        var count: Int32 = 0
        let status = LIBMTP_Detect_Raw_Devices(&devices, &count)
        defer { free(devices) }
        if status == LIBMTP_ERROR_NO_DEVICE_ATTACHED {
            return try run(.init(start: nil, count: 0))
        }
        guard status == LIBMTP_ERROR_NONE else {
            throw USBError(L10n.text("USB device detection failed (libmtp code %@).", String(status.rawValue)))
        }
        return try run(.init(start: devices, count: Int(count)))
    }

    package init(rawDevice: UnsafeMutablePointer<LIBMTP_raw_device_t>) throws {
        guard let device = LIBMTP_Open_Raw_Device_Uncached(rawDevice) else {
            throw USBError(L10n.text("Could not open the MTP session. Unlock the phone, close other MTP apps, and reconnect the cable."))
        }
        self.device = device
    }

    deinit {
        LIBMTP_Release_Device(device)
    }

    package func storages() throws -> [(id: UInt32, name: String, freeBytes: UInt64)] {
        // libmtp reads the storage list when opening this command's session.
        guard device.pointee.storage != nil else {
            throw failure(L10n.text("Could not read storages. Unlock the phone and allow file access."))
        }
        var result: [(UInt32, String, UInt64)] = []
        var node = device.pointee.storage
        while let storage = node?.pointee {
            let name = storage.StorageDescription.map { String(cString: $0) } ?? L10n.text("Unnamed storage")
            result.append((storage.id, name, storage.FreeSpaceInBytes))
            node = storage.next
        }
        return result
    }

    package func entries(storage: UInt32, folder: UInt32) throws -> [Entry] {
        var result: [Entry] = []
        try visitEntries(storage: storage, folder: folder) { entry, _ in result.append(entry) }
        return result
    }

    package func visitEntries(
        storage: UInt32,
        folder: UInt32,
        visit: (Entry, Int) throws -> Void
    ) throws {
        try withChildren(storage: storage, folder: folder) { children in
            for object in children {
                try visit(entry(for: object), children.count)
            }
        }
    }

    package func childIDs(storage: UInt32, folder: UInt32) throws -> Set<UInt32> {
        try withChildren(storage: storage, folder: folder) { Set($0) }
    }

    package func entryMatches(_ expected: Entry, storage: UInt32, folder: UInt32) throws -> Bool {
        let pointer = try metadata(for: expected.id)
        defer { LIBMTP_destroy_file_t(pointer) }
        let object = pointer.pointee
        let isInFolder = object.parent_id == folder || (folder == Self.root && object.parent_id == 0)
        guard object.storage_id == storage, isInFolder else { return false }
        return try entry(from: object) == expected
    }

    private func entry(for object: UInt32) throws -> Entry {
        let pointer = try metadata(for: object)
        defer { LIBMTP_destroy_file_t(pointer) }
        return try entry(from: pointer.pointee)
    }

    private func entry(from file: LIBMTP_file_t) throws -> Entry {
        guard let filename = file.filename else {
            throw USBError(L10n.text("MTP object %@ has no filename.", String(file.item_id)))
        }
        return Entry(
            id: file.item_id,
            name: String(cString: filename),
            size: file.filesize,
            isFolder: file.filetype == LIBMTP_FILETYPE_FOLDER,
            modifiedAt: file.modificationdate > 0
                ? Date(timeIntervalSince1970: TimeInterval(file.modificationdate)) : nil
        )
    }

    private func withChildren<Result>(
        storage: UInt32,
        folder: UInt32,
        read: (UnsafeBufferPointer<UInt32>) throws -> Result
    ) throws -> Result {
        if folder == Self.root {
            guard try storages().contains(where: { $0.id == storage }) else {
                throw USBError(L10n.text("The selected MTP storage is unavailable. Refresh the storage list."))
            }
        } else {
            let parent = try metadata(for: folder)
            defer { LIBMTP_destroy_file_t(parent) }
            guard parent.pointee.filetype == LIBMTP_FILETYPE_FOLDER, parent.pointee.storage_id == storage else {
                throw USBError(L10n.text("The folder does not belong to the selected storage."))
            }
        }

        LIBMTP_Clear_Errorstack(device)
        var children: UnsafeMutablePointer<UInt32>?
        let count = LIBMTP_Get_Children(device, storage, folder, &children)
        guard count >= 0 else { throw failure(L10n.text("Could not list the folder.")) }
        guard count > 0 else { return try read(.init(start: nil, count: 0)) }
        guard let children else { throw USBError(L10n.text("The device returned no folder entries.")) }
        defer { free(children) }

        return try read(UnsafeBufferPointer(start: children, count: Int(count)))
    }

    package func thumbnail(object: UInt32) -> Data? {
        LIBMTP_Clear_Errorstack(device)
        var bytes: UnsafeMutablePointer<UInt8>?
        var size: UInt32 = 0
        defer {
            free(bytes)
            LIBMTP_Clear_Errorstack(device)
        }
        let result = LIBMTP_Get_Thumbnail(device, object, &bytes, &size)
        guard result == 0, let bytes, size > 0, size <= 2 * 1024 * 1024 else { return nil }
        return Data(bytes: bytes, count: Int(size))
    }

    package func pull(
        object: UInt32,
        to destination: URL,
        progress: @escaping (UInt64, UInt64) -> Void = { _, _ in },
        discard: () -> Bool = { false }
    ) throws {
        let info = try metadata(for: object)
        defer { LIBMTP_destroy_file_t(info) }
        guard info.pointee.filetype != LIBMTP_FILETYPE_FOLDER else {
            throw USBError(L10n.text("Pull requires a file object ID."))
        }
        try DownloadFile.write(to: destination, expectedBytes: info.pointee.filesize) { file in
            try reporting(progress) { callback, context in
                LIBMTP_Clear_Errorstack(device)
                let status = LIBMTP_Get_File_To_File_Descriptor(
                    device, object, file.fileDescriptor, callback, context
                )
                guard status == 0 else { throw failure(L10n.text("Download failed.")) }
            }
            if discard() { throw CancellationError() }
        }
    }

    package func push(
        source: URL,
        storage: UInt32,
        folder: UInt32,
        as targetName: String? = nil,
        progress: @escaping (UInt64, UInt64) -> Void = { _, _ in }
    ) throws -> UInt32 {
        let descriptor = source.withUnsafeFileSystemRepresentation { droidbridge_open_source($0) }
        guard descriptor >= 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        defer { close(descriptor) }
        var info = stat()
        guard fstat(descriptor, &info) == 0,
              (info.st_mode & S_IFMT) == S_IFREG,
              let bytes = UInt64(exactly: info.st_size) else {
            throw USBError(L10n.text("Push requires a readable regular file."))
        }

        let name = targetName ?? source.lastPathComponent
        try validateName(name)
        let existing = try entries(storage: storage, folder: folder)
        guard !existing.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) else {
            throw USBError(L10n.text("The destination already contains %@. Rename the source before retrying.", name))
        }
        guard let file = LIBMTP_new_file_t() else {
            throw USBError(L10n.text("Could not allocate MTP file metadata."))
        }
        defer { LIBMTP_destroy_file_t(file) }
        guard let filename = strdup(name) else { throw USBError(L10n.text("Could not allocate the MTP filename.")) }
        file.pointee.filename = filename
        file.pointee.filesize = bytes
        file.pointee.filetype = LIBMTP_FILETYPE_UNKNOWN
        file.pointee.storage_id = storage
        file.pointee.parent_id = folder

        var sourceDescriptor = descriptor
        try reporting(progress) { callback, context in
            LIBMTP_Clear_Errorstack(device)
            let status = LIBMTP_Send_File_From_Handler(
                device, droidbridge_read_upload, &sourceDescriptor, file, callback, context
            )
            guard status == 0 else {
                throw failure(L10n.text("Upload failed. Check the destination on the phone for a partial file before retrying."))
            }
        }
        return file.pointee.item_id
    }

    package func createFolder(_ name: String, storage: UInt32, parent: UInt32) throws -> UInt32 {
        try validateName(name)
        let existing = try entries(storage: storage, folder: parent)
        guard !existing.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) else {
            throw USBError(L10n.text("The destination already contains %@.", name))
        }
        LIBMTP_Clear_Errorstack(device)
        var filename = name.utf8CString
        let id = filename.withUnsafeMutableBufferPointer {
            LIBMTP_Create_Folder(device, $0.baseAddress, parent, storage)
        }
        guard id != 0 else { throw failure(L10n.text("Could not create the destination folder.")) }
        return id
    }

    private func validateName(_ name: String) throws {
        guard TransferName.isComponent(name), name.utf8.count <= 254 else {
            throw USBError(L10n.text("The name must be a valid filename of at most 254 UTF-8 bytes."))
        }
    }

    private func metadata(for object: UInt32) throws -> UnsafeMutablePointer<LIBMTP_file_t> {
        LIBMTP_Clear_Errorstack(device)
        guard let file = LIBMTP_Get_Filemetadata(device, object) else {
            throw failure(L10n.text("Could not read object %@. Refresh the folder to get current IDs.", String(object)))
        }
        return file
    }

    private func failure(_ message: String) -> USBError {
        defer { LIBMTP_Clear_Errorstack(device) }
        var details: [String] = [message]
        var node = LIBMTP_Get_Errorstack(device)
        while let error = node?.pointee {
            if let text = error.error_text { details.append(String(cString: text)) }
            node = error.next
        }
        return USBError(details.joined(separator: "\n"))
    }
}

private final class ProgressContext {
    let report: (UInt64, UInt64) -> Void

    init(_ report: @escaping (UInt64, UInt64) -> Void) {
        self.report = report
    }
}

private func reporting(
    _ progress: @escaping (UInt64, UInt64) -> Void,
    transfer: (LIBMTP_progressfunc_t, UnsafeRawPointer) throws -> Void
) rethrows {
    let context = ProgressContext(progress)
    try withExtendedLifetime(context) {
        try transfer({ sent, total, pointer in
            if let pointer {
                Unmanaged<ProgressContext>.fromOpaque(pointer).takeUnretainedValue().report(sent, total)
            }
            return 0
        }, Unmanaged.passUnretained(context).toOpaque())
    }
}
