import DroidBridgeCore
import AppKit
import DroidBridgeMTP
import Observation
import SwiftUI

struct BrowserItem: Identifiable, Equatable {
    let id: String
    let name: String
    let isFolder: Bool
    let size: UInt64?
    var modifiedAt: Date?
    var localURL: URL?
    var remote: MTPSession.Entry?
}

@Observable
final class TransferJob: Identifiable {
    enum State: Equatable, Sendable {
        case queued, copying, waitingToCancel, conflict, completed, skipped, cancelled, failed(String)

        var isFinal: Bool {
            switch self {
            case .completed, .skipped, .cancelled, .failed: true
            default: false
            }
        }
    }

    let id = UUID()
    let batchID: UUID
    let source: TransferSource
    let control = TransferControl()
    var state: State = .queued
    var progress: Double?
    var currentName: String?
    var keepBoth = false

    init(batchID: UUID, source: TransferSource) {
        self.batchID = batchID
        self.source = source
    }

    var canCancel: Bool {
        switch state {
        case .queued, .conflict: true
        case .copying: source.toMac
        default: false
        }
    }
}

@MainActor
@Observable
final class BrowserModel {
    var macFolder = FileManager.default.homeDirectoryForCurrentUser
    var macItems: [BrowserItem] = []
    var macSelection: Set<String> = []
    var macError: String?

    var connection: PhoneConnection?
    var phonePath: [PhoneFolder] = []
    var phoneItems: [BrowserItem] = []
    var phoneSelection: Set<String> = []
    var phoneError: String?
    var connecting = false
    var readingPhone = false
    private(set) var loadingPhoneFolder: String?
    private(set) var phoneEntryCount: Int?
    var showPhonePreviews = false

    private(set) var jobs: [TransferJob] = []
    private(set) var pendingJobCount = 0
    private(set) var activeJob: UUID?
    private var displayedTransferID: UUID?
    private var runningDownloadBatch: UUID?
    private let engine = TransferEngine()
    private var jobIndices: [UUID: Int] = [:]
    private var nextJobIndex = 0
    private var skipConflictsForBatch: Set<UUID> = []
    private var macRefreshPending = false
    private var nextMacRefresh = ContinuousClock.now

    var phoneFolder: PhoneFolder? { phonePath.last }
    var selectedMac: [BrowserItem] { macItems.filter { macSelection.contains($0.id) } }
    var selectedPhone: [BrowserItem] { phoneItems.filter { phoneSelection.contains($0.id) } }
    var phoneNavigationAllowed: Bool { !connecting && !readingPhone && activeJob == nil }
    var currentTransfer: TransferJob? {
        displayedTransferID.flatMap { jobIndices[$0] }.map { jobs[$0] }
    }
    var downloadConflict: TransferJob? {
        guard jobs.indices.contains(nextJobIndex), case .conflict = jobs[nextJobIndex].state,
              jobs[nextJobIndex].source.toMac else { return nil }
        return jobs[nextJobIndex]
    }

    func loadPreview(for item: BrowserItem, in folder: PhoneFolder, key: String) async throws -> CGImage? {
        guard showPhonePreviews, phoneNavigationAllowed, loadingPhoneFolder == nil,
              phoneFolder == folder, let entry = item.remote else { return nil }
        return try await engine.thumbnail(entry, in: folder, key: key)
    }

    func start() async {
        loadMac()
        await connect()
        while !Task.isCancelled {
            do {
                try await Task.sleep(for: .seconds(3))
                guard phoneNavigationAllowed else { continue }
                if let id = connection?.id {
                    if try await engine.isConnected(id) { continue }
                }
                await connect(showSpinner: false)
            } catch is CancellationError {
                break
            } catch {
                phoneError = error.localizedDescription
            }
        }
    }

    func chooseMacFolder() {
        let chooser = NSOpenPanel()
        chooser.title = L10n.text("Mac Folder")
        chooser.canChooseDirectories = true
        chooser.canChooseFiles = false
        chooser.allowsMultipleSelection = false
        chooser.directoryURL = macFolder
        guard chooser.runModal() == .OK, let url = chooser.url else { return }
        openMac(url)
    }

    func openMac(_ url: URL) {
        if macFolder != url { macSelection = [] }
        macFolder = url
        loadMac()
    }

    func loadMac() {
        macRefreshPending = false
        nextMacRefresh = ContinuousClock.now.advanced(by: .seconds(5))
        do {
            let keys: Set<URLResourceKey> = [
                .isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey, .contentModificationDateKey
            ]
            let urls = try FileManager.default.contentsOfDirectory(
                at: macFolder, includingPropertiesForKeys: Array(keys), options: .skipsHiddenFiles
            )
            macItems = Self.sorted(urls.compactMap { url in
                guard let values = try? url.resourceValues(forKeys: keys),
                      values.isSymbolicLink != true,
                      values.isDirectory == true || values.isRegularFile == true else { return nil }
                return BrowserItem(id: url.path, name: url.lastPathComponent, isFolder: values.isDirectory == true,
                                   size: values.fileSize.flatMap(UInt64.init(exactly:)),
                                   modifiedAt: values.contentModificationDate, localURL: url)
            })
            macSelection.formIntersection(macItems.map(\.id))
            macError = nil
        } catch {
            macItems = []
            macSelection = []
            macError = error.localizedDescription
        }
    }

    func connect(showSpinner: Bool = true) async {
        guard phoneNavigationAllowed else { return }
        readingPhone = true
        connecting = showSpinner
        phoneError = nil
        defer {
            readingPhone = false
            connecting = false
            startNextJob()
        }
        do {
            connection = try await engine.connect()
            phonePath = []
            phoneItems = []
            phoneSelection = []
            if let first = connection?.storages.first {
                let root = try storageRoot(first)
                try await loadPath([root])
            }
        } catch {
            connection = nil
            phonePath = []
            phoneItems = []
            phoneSelection = []
            phoneError = error.localizedDescription
        }
    }

    func selectStorage(_ storage: PhoneStorage) async {
        guard phoneNavigationAllowed, let root = try? storageRoot(storage) else { return }
        await navigate([root])
    }

    func openPhone(_ item: BrowserItem) async {
        guard let entry = item.remote, entry.isFolder, let current = phoneFolder else { return }
        let next = PhoneFolder(connection: current.connection, storage: current.storage, id: entry.id, name: entry.name)
        await navigate(phonePath + [next])
    }

    func phoneUp() async {
        guard phonePath.count > 1 else { return }
        await navigate(Array(phonePath.dropLast()))
    }

    func refresh() async {
        loadMac()
        guard phoneNavigationAllowed else { return }
        if connection != nil, !phonePath.isEmpty {
            await navigate(phonePath)
        } else {
            await connect()
        }
    }

    @discardableResult
    func upload(_ urls: [URL]) -> Bool {
        guard let destination = phoneFolder, !readingPhone else { return false }
        return enqueue(urls.filter(\.isFileURL).map { .mac($0, to: destination) })
    }

    @discardableResult
    func download(ids: [String], from origin: PhoneFolder? = nil) -> Bool {
        guard let folder = phoneFolder, !readingPhone, origin == nil || folder == origin else { return false }
        let selected = Set(ids)
        let entries = phoneItems.filter { selected.contains($0.id) }.compactMap(\.remote)
        return enqueue(entries.map { .phone($0, from: folder, to: macFolder) })
    }

    func cancel(_ id: UUID) {
        guard let index = jobIndices[id], jobs[index].canCancel else { return }
        let job = jobs[index]
        if runningDownloadBatch == job.batchID && job.state != .conflict {
            job.control.cancel()
            jobs[index].state = .waitingToCancel
        } else {
            finishJob(at: index, as: .cancelled)
            startNextJob()
        }
    }

    func keepBoth(_ id: UUID) {
        guard let index = jobIndices[id], case .conflict = jobs[index].state else { return }
        jobs[index].keepBoth = true
        jobs[index].state = .queued
        startNextJob()
    }

    func skipDownloadConflicts(_ id: UUID) {
        guard let job = downloadConflict, job.id == id, let index = jobIndices[id] else { return }
        skipConflictsForBatch.insert(job.batchID)
        finishJob(at: index, as: .skipped)
        startNextJob()
    }

    func clearFinished() {
        jobs.removeAll { $0.state.isFinal && $0.id != displayedTransferID }
        jobIndices = Dictionary(uniqueKeysWithValues: jobs.enumerated().map { ($0.element.id, $0.offset) })
        skipConflictsForBatch.formIntersection(jobs.map(\.batchID))
        nextJobIndex = 0
    }

    private func enqueue(_ sources: [TransferSource]) -> Bool {
        guard !sources.isEmpty else { return false }
        let batchID = UUID()
        let newJobs = sources.map { TransferJob(batchID: batchID, source: $0) }
        for (offset, job) in newJobs.enumerated() {
            jobIndices[job.id] = jobs.count + offset
        }
        jobs.append(contentsOf: newJobs)
        pendingJobCount += newJobs.count
        startNextJob()
        return true
    }

    private func storageRoot(_ storage: PhoneStorage) throws -> PhoneFolder {
        guard let connection else { throw CancellationError() }
        return PhoneFolder(connection: connection.id, storage: storage.id, id: MTPSession.root, name: storage.name)
    }

    private func navigate(_ path: [PhoneFolder]) async {
        guard phoneNavigationAllowed else { return }
        readingPhone = true
        defer {
            readingPhone = false
            startNextJob()
        }
        do {
            try await loadPath(path)
        } catch {
            phoneError = error.localizedDescription
        }
    }

    private func loadPath(_ path: [PhoneFolder]) async throws {
        guard let folder = path.last else { return }
        loadingPhoneFolder = folder.name
        let same = phonePath.last == path.last
        var firstPage = true
        defer {
            loadingPhoneFolder = nil
            phoneEntryCount = nil
            if !firstPage {
                phoneSelection.formIntersection(phoneItems.map(\.id))
            }
        }
        for try await page in engine.list(folder) {
            if firstPage {
                firstPage = false
                phonePath = path
                phoneItems = []
                phoneError = nil
                if !same { phoneSelection = [] }
            }
            phoneItems.append(contentsOf: page.entries.map {
                BrowserItem(id: String($0.id), name: $0.name, isFolder: $0.isFolder,
                            size: $0.size, modifiedAt: $0.modifiedAt, remote: $0)
            })
            phoneEntryCount = page.total
        }
        phoneError = nil
    }

    private func startNextJob() {
        guard activeJob == nil, !readingPhone, !connecting else { return }
        while jobs.indices.contains(nextJobIndex), jobs[nextJobIndex].state.isFinal {
            nextJobIndex += 1
        }
        let index = nextJobIndex
        guard jobs.indices.contains(index), case .queued = jobs[index].state else {
            if macRefreshPending { loadMac() }
            return
        }

        let job = jobs[index]
        switch job.source {
        case .phone:
            startDownloadBatch(at: index, first: job)
        case .mac(let url, let folder):
            startUpload(at: index, job: job, url: url, folder: folder)
        }
    }

    private func startDownloadBatch(at index: Int, first: TransferJob) {
        let requests = jobs[index...].prefix { $0.batchID == first.batchID }.compactMap { job -> DownloadRequest? in
            guard case .queued = job.state, case .phone(let entry, let folder, let destination) = job.source else {
                return nil
            }
            return DownloadRequest(id: job.id, entry: entry, folder: folder,
                                   destination: destination, keepBoth: job.keepBoth, control: job.control)
        }
        activeJob = first.id
        displayedTransferID = first.id
        runningDownloadBatch = first.batchID
        jobs[index].state = .copying

        let reports = engine.downloads(requests, batchID: first.batchID,
                                       skipConflicts: skipConflictsForBatch.contains(first.batchID))
        Task {
            for await report in reports { apply(report) }
            // A conflict can stop the worker before it sees a queued cancellation.
            for request in requests where request.control.isCancelled {
                if let index = jobIndices[request.id], jobs[index].state == .waitingToCancel {
                    finishJob(at: index, as: .cancelled)
                }
            }
            runningDownloadBatch = nil
            displayedTransferID = nil
            activeJob = nil
            startNextJob()
        }
    }

    private func apply(_ report: DownloadReport) {
        for result in report.results {
            guard let index = jobIndices[result.id] else { continue }
            let state = result.state == .conflict && jobs[index].control.isCancelled ? .cancelled : result.state
            finishJob(at: index, as: state)
            if result.destination?.deletingLastPathComponent().standardizedFileURL == macFolder.standardizedFileURL {
                macRefreshPending = true
            }
        }
        if let current = report.current, let index = jobIndices[current.id], !jobs[index].state.isFinal {
            displayedTransferID = current.id
            if jobs[index].state == .queued { jobs[index].state = .copying }
            jobs[index].currentName = current.name
            jobs[index].progress = current.fraction
        }
        if macRefreshPending && ContinuousClock.now >= nextMacRefresh { loadMac() }
    }

    private func startUpload(at index: Int, job: TransferJob, url: URL, folder: PhoneFolder) {
        activeJob = job.id
        displayedTransferID = job.id
        jobs[index].state = .copying
        let jobID = job.id

        Task {
            let state: TransferJob.State
            do {
                try await engine.upload(url, to: folder, keepBoth: job.keepBoth, control: job.control) { [weak self] name, fraction in
                    Task { @MainActor in self?.update(jobID, name: name, fraction: fraction) }
                }
                state = .completed
            } catch is TransferConflict {
                state = .conflict
            } catch is CancellationError {
                state = .cancelled
            } catch {
                state = .failed(error.localizedDescription)
            }
            if let current = jobIndices[job.id] { finishJob(at: current, as: state) }
            if phoneFolder?.connection == folder.connection {
                do {
                    try await loadPath(phonePath)
                } catch {
                    phoneError = error.localizedDescription
                }
            }
            displayedTransferID = nil
            activeJob = nil
            startNextJob()
        }
    }

    private func finishJob(at index: Int, as state: TransferJob.State) {
        if state.isFinal && !jobs[index].state.isFinal { pendingJobCount -= 1 }
        jobs[index].state = state
    }

    private func update(_ id: UUID, name: String, fraction: Double?) {
        guard activeJob == id, let index = jobIndices[id], !jobs[index].state.isFinal else { return }
        jobs[index].currentName = name
        jobs[index].progress = fraction
    }

    private static func sorted(_ items: [BrowserItem]) -> [BrowserItem] {
        items.sorted {
            if $0.isFolder != $1.isFolder { return $0.isFolder }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }
}
