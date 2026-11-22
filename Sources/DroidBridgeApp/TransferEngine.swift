import Darwin
import DroidBridgeCore
import DroidBridgeMTP
import Foundation
import ImageIO
import Synchronization

struct PhoneFolder: Sendable, Equatable, Codable {
    let connection: UUID
    let storage: UInt32
    let id: UInt32
    let name: String
}

struct PhoneStorage: Identifiable, Sendable {
    let id: UInt32
    let name: String
    let freeBytes: UInt64
}

struct PhoneConnection: Sendable {
    let id: UUID
    let name: String
    let storages: [PhoneStorage]
}

struct FolderPage: Sendable {
    let entries: [MTPSession.Entry]
    let total: Int
}

struct TransferConflict: LocalizedError {
    let name: String
    var errorDescription: String? { "Объект «\(name)» уже есть в папке назначения." }
}

enum TransferSource: Sendable {
    case mac(URL, to: PhoneFolder)
    case phone(MTPSession.Entry, from: PhoneFolder, to: URL)

    var name: String {
        switch self {
        case .mac(let url, _): url.lastPathComponent
        case .phone(let entry, _, _): entry.name
        }
    }

    var toMac: Bool {
        if case .phone = self { return true }
        return false
    }

    var connection: UUID {
        switch self {
        case .mac(_, let folder), .phone(_, let folder, _): folder.connection
        }
    }
}

final class TransferControl: Sendable {
    private let cancelled = Atomic(false)
    var isCancelled: Bool { cancelled.load(ordering: .relaxed) }
    func cancel() { cancelled.store(true, ordering: .relaxed) }

    func check() throws {
        if isCancelled { throw CancellationError() }
    }
}

struct DownloadRequest: Sendable {
    let id: UUID
    let entry: MTPSession.Entry
    let folder: PhoneFolder
    let destination: URL
    let keepBoth: Bool
    let control: TransferControl
}

private struct USBIdentity: Equatable {
    let bus: UInt32
    let address: UInt8
    let vendor: UInt16
    let product: UInt16
}

private final class CachedThumbnail {
    let image: CGImage?

    init(_ image: CGImage?) {
        self.image = image
    }
}

private final class DownloadBatch {
    let id: UUID
    let folder: PhoneFolder
    let destination: URL
    let childIDs: Set<UInt32>
    var names: TransferName.Index

    init(id: UUID, folder: PhoneFolder, destination: URL, session: MTPSession) throws {
        self.id = id
        self.folder = folder
        self.destination = destination
        childIDs = try session.childIDs(storage: folder.storage, folder: folder.id)
        names = TransferName.Index(try FileManager.default.contentsOfDirectory(atPath: destination.path))
    }
}

// The queue owns every access to the libmtp pointer, including session release.
final class TransferEngine: @unchecked Sendable {
    private let queue = DispatchQueue(label: "droidbridge.usb", qos: .userInitiated)
    private var session: MTPSession?
    private var connection: PhoneConnection?
    private var identity: USBIdentity?
    private var downloadBatch: DownloadBatch?
    private let thumbnails: NSCache<NSString, CachedThumbnail> = {
        let cache = NSCache<NSString, CachedThumbnail>()
        cache.countLimit = 192
        cache.totalCostLimit = 8 * 1024 * 1024
        return cache
    }()

    func connect() async throws -> PhoneConnection? {
        try await run { engine in
            engine.session = nil
            engine.connection = nil
            engine.identity = nil
            engine.downloadBatch = nil
            engine.thumbnails.removeAllObjects()
            return try MTPSession.withDevices { devices in
                guard !devices.isEmpty, let raw = devices.baseAddress else { return nil }
                guard devices.count == 1 else { throw USBError("Подключите один Android по USB.") }
                let native = try MTPSession(rawDevice: raw)
                let storages = try native.storages().map {
                    PhoneStorage(id: $0.id, name: $0.name, freeBytes: $0.freeBytes)
                }
                let entry = raw.pointee.device_entry
                let name = entry.product.map { String(cString: $0) } ?? "Android"
                let connection = PhoneConnection(id: UUID(), name: name, storages: storages)
                engine.session = native
                engine.connection = connection
                engine.identity = USBIdentity(
                    bus: raw.pointee.bus_location, address: raw.pointee.devnum,
                    vendor: entry.vendor_id, product: entry.product_id
                )
                return connection
            }
        }
    }

    func isConnected(_ id: UUID) async throws -> Bool {
        try await run { engine in
            guard engine.connection?.id == id, let identity = engine.identity else { return false }
            return try MTPSession.withDevices { devices in
                devices.count == 1 && devices.contains {
                    identity == USBIdentity(
                        bus: $0.bus_location, address: $0.devnum,
                        vendor: $0.device_entry.vendor_id, product: $0.device_entry.product_id
                    )
                }
            }
        }
    }

    func list(_ folder: PhoneFolder) -> AsyncThrowingStream<FolderPage, Error> {
        AsyncThrowingStream { continuation in
            let control = TransferControl()
            continuation.onTermination = { _ in control.cancel() }
            queue.async {
                do {
                    try control.check()
                    let session = try self.connected(folder.connection)
                    var page: [MTPSession.Entry] = []
                    var total = 0
                    var nextUpdate = ContinuousClock.now
                    try session.visitEntries(storage: folder.storage, folder: folder.id) { entry, count in
                        try control.check()
                        total = count
                        page.append(entry)
                        let now = ContinuousClock.now
                        if now >= nextUpdate {
                            continuation.yield(FolderPage(entries: page, total: count))
                            page.removeAll(keepingCapacity: true)
                            nextUpdate = now.advanced(by: .milliseconds(350))
                        }
                    }
                    if !page.isEmpty || total == 0 {
                        continuation.yield(FolderPage(entries: page, total: total))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func thumbnail(_ entry: MTPSession.Entry, in folder: PhoneFolder, key: String) async throws -> CGImage? {
        let control = TransferControl()
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await run { engine in
                try control.check()
                let session = try engine.connected(folder.connection)
                let cacheKey = key as NSString
                if let cached = engine.thumbnails.object(forKey: cacheKey) { return cached.image }
                let image = session.thumbnail(object: entry.id).flatMap(Self.decodeThumbnail)
                engine.thumbnails.setObject(
                    CachedThumbnail(image), forKey: cacheKey,
                    cost: image.map { $0.bytesPerRow * $0.height } ?? 0
                )
                try control.check()
                return image
            }
        } onCancel: {
            control.cancel()
        }
    }

    private static func decodeThumbnail(_ data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateThumbnailAtIndex(source, 0, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 96
        ] as CFDictionary)
    }

    func upload(
        _ url: URL,
        to folder: PhoneFolder,
        keepBoth: Bool,
        control: TransferControl,
        progress: @escaping @Sendable (String, Double?) -> Void
    ) async throws {
        try await run { engine in
            let session = try engine.connected(folder.connection)
            try control.check()
            engine.downloadBatch = nil
            let transfer = CopyOperation(session: session, control: control, progress: progress)
            try transfer.copyToPhone(url, destination: folder, keepBoth: keepBoth)
        }
    }

    func downloads(
        _ requests: [DownloadRequest], batchID: UUID, skipConflicts: Bool
    ) -> AsyncStream<DownloadReport> {
        AsyncStream { continuation in
            queue.async {
                runDownloads(requests, id: \.id, skipConflicts: skipConflicts) { request, progress in
                    try self.copyDownload(request, batchID: batchID, progress: progress)
                } report: {
                    continuation.yield($0)
                }
                continuation.finish()
            }
        }
    }

    private func copyDownload(
        _ request: DownloadRequest, batchID: UUID, progress: @escaping (String, Double?) -> Void
    ) throws -> URL {
        try request.control.check()
        let session = try connected(request.folder.connection)
        let batch: DownloadBatch
        if let current = downloadBatch, current.id == batchID,
           current.folder == request.folder, current.destination == request.destination {
            batch = current
        } else {
            batch = try DownloadBatch(id: batchID, folder: request.folder,
                                      destination: request.destination, session: session)
            downloadBatch = batch
        }
        let transfer = CopyOperation(session: session, control: request.control, progress: progress)
        return try transfer.copyToMac(request.entry, batch: batch, keepBoth: request.keepBoth)
    }

    private func connected(_ id: UUID) throws -> MTPSession {
        guard connection?.id == id, let session else {
            throw USBError("Телефон был переподключён. Выберите файлы для передачи заново.")
        }
        return session
    }

    private func run<Value: Sendable>(
        _ action: @escaping @Sendable (TransferEngine) throws -> Value
    ) async throws -> Value {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                continuation.resume(with: Result { try action(self) })
            }
        }
    }
}

private struct LocalCopyItem {
    let url: URL
    let children: [LocalCopyItem]?
}

private struct CopyOperation {
    let session: MTPSession
    let control: TransferControl
    let progress: (String, Double?) -> Void

    func copyToPhone(_ url: URL, destination: PhoneFolder, keepBoth: Bool) throws {
        let item = try prepareUpload(url)
        let names = try session.entries(storage: destination.storage, folder: destination.id).map(\.name)
        let name = try targetName(url.lastPathComponent, TransferName.Index(names),
                                  isFolder: item.children != nil, keepBoth: keepBoth)
        try upload(item, name: name, storage: destination.storage, parent: destination.id)
    }

    func copyToMac(_ entry: MTPSession.Entry, batch: DownloadBatch, keepBoth: Bool) throws -> URL {
        let name = try targetName(entry.name, batch.names, isFolder: entry.isFolder, keepBoth: keepBoth)
        guard batch.childIDs.contains(entry.id),
              try session.entryMatches(entry, storage: batch.folder.storage, folder: batch.folder.id) else {
            throw USBError("Объект на телефоне изменился. Обновите папку и выберите его заново.")
        }
        let target = batch.destination.appending(path: name)
        do {
            try download(entry, storage: batch.folder.storage, to: target, ancestors: [])
        } catch let error as POSIXError where error.code == .EEXIST {
            batch.names.insert(name)
            throw TransferConflict(name: name)
        }
        batch.names.insert(name)
        return target
    }

    private func targetName(_ requested: String, _ names: TransferName.Index, isFolder: Bool, keepBoth: Bool) throws -> String {
        guard TransferName.isComponent(requested) else { throw USBError("Недопустимое имя файла или папки.") }
        let available = names.available(requested, isFolder: isFolder)
        guard keepBoth || available == requested else { throw TransferConflict(name: requested) }
        return available
    }

    private func upload(_ item: LocalCopyItem, name: String, storage: UInt32, parent: UInt32) throws {
        try control.check()
        if let children = item.children {
            progress(name, nil)
            let folder = try session.createFolder(name, storage: storage, parent: parent)
            var names: [String] = []
            for child in children {
                let name = TransferName.available(child.url.lastPathComponent, among: names,
                                                  isFolder: child.children != nil)
                try upload(child, name: name, storage: storage, parent: folder)
                names.append(name)
            }
        } else {
            _ = try session.push(source: item.url, storage: storage, folder: parent, as: name, progress: reporting(name))
        }
    }

    private func download(_ entry: MTPSession.Entry, storage: UInt32, to target: URL, ancestors: Set<UInt32>) throws {
        try control.check()
        guard TransferName.isComponent(entry.name), !ancestors.contains(entry.id) else {
            throw USBError("Телефон вернул недопустимое имя или цикл папок.")
        }
        guard entry.isFolder else {
            try session.pull(object: entry.id, to: target, progress: reporting(entry.name)) { control.isCancelled }
            return
        }

        // Build folder copies off to the side and publish only a complete tree.
        let temporary = target.deletingLastPathComponent()
            .appending(path: ".droidbridge-" + UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(
            at: temporary, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700]
        )
        var published = false
        defer {
            if !published { try? FileManager.default.removeItem(at: temporary) }
        }
        progress(entry.name, nil)
        var names: [String] = []
        for child in try session.entries(storage: storage, folder: entry.id) {
            guard TransferName.isComponent(child.name) else { throw USBError("Недопустимое имя файла на телефоне.") }
            let name = TransferName.available(child.name, among: names, isFolder: child.isFolder)
            do {
                try download(child, storage: storage, to: temporary.appending(path: name),
                             ancestors: ancestors.union([entry.id]))
            } catch let error as POSIXError where error.code == .EEXIST {
                throw USBError("Не удалось выбрать свободное имя для «\(child.name)» внутри папки.")
            }
            names.append(name)
        }
        try control.check()
        let status = temporary.withUnsafeFileSystemRepresentation { sourcePath in
            target.withUnsafeFileSystemRepresentation { destinationPath in
                renamex_np(sourcePath, destinationPath, UInt32(RENAME_EXCL))
            }
        }
        guard status == 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        published = true
    }

    private func prepareUpload(_ url: URL) throws -> LocalCopyItem {
        try control.check()
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .isDirectoryKey, .isSymbolicLinkKey, .isReadableKey]
        let values = try url.resourceValues(forKeys: keys)
        guard values.isSymbolicLink != true, values.isReadable == true,
              values.isRegularFile == true || values.isDirectory == true else {
            throw USBError("Не удаётся прочитать «\(url.lastPathComponent)» как обычный файл или папку.")
        }
        guard values.isDirectory == true else { return LocalCopyItem(url: url, children: nil) }
        let urls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: Array(keys))
        let children = try urls.compactMap { child -> LocalCopyItem? in
            if try child.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == true { return nil }
            return try prepareUpload(child)
        }
        return LocalCopyItem(url: url, children: children)
    }

    private func reporting(_ name: String) -> (UInt64, UInt64) -> Void {
        progress(name, 0)
        var nextUpdate = ContinuousClock.now.advanced(by: .milliseconds(125))
        return { sent, total in
            guard total > 0 else { return }
            let now = ContinuousClock.now
            guard sent >= total || now >= nextUpdate else { return }
            nextUpdate = now.advanced(by: .milliseconds(125))
            progress(name, Double(min(sent, total)) / Double(total))
        }
    }
}
