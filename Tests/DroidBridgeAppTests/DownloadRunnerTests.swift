@testable import DroidBridgeApp
import Foundation
import Testing

struct DownloadRunnerTests {
    @Test func reportsTheCurrentFileBeforeReceivingUSBProgress() {
        let job = UUID()
        var current: UUID?
        runDownloads([job], id: { $0 }, skipConflicts: false) { _, _ in
            #expect(current == job)
            return URL(fileURLWithPath: "/tmp/completed.jpg")
        } report: { update in
            if let progress = update.current { current = progress.id }
        }
    }

    @Test func stopsAtUnresolvedConflictAndKeepsEarlierResults() {
        let first = UUID()
        let conflict = UUID()
        let later = UUID()
        var started: [UUID] = []
        var outcomes: [DownloadResult] = []

        runDownloads([first, conflict, later], id: { $0 }, skipConflicts: false) { id, _ in
            started.append(id)
            if id == conflict { throw TransferConflict(name: "same.jpg") }
            return URL(fileURLWithPath: "/tmp/completed.jpg")
        } report: { update in
            outcomes.append(contentsOf: update.results)
        }

        #expect(started == [first, conflict])
        #expect(outcomes.map(\.id) == [first, conflict])
        #expect(outcomes[0].state == .completed)
        #expect(outcomes[1].state == .conflict)
    }

    @Test func continuesPastSkippedNamesAndCancelledItems() {
        let duplicate = UUID()
        let cancelled = UUID()
        let last = UUID()
        var outcomes: [DownloadResult] = []

        runDownloads([duplicate, cancelled, last], id: { $0 }, skipConflicts: true) { id, _ in
            if id == duplicate { throw TransferConflict(name: "same.jpg") }
            if id == cancelled { throw CancellationError() }
            return URL(fileURLWithPath: "/tmp/completed.jpg")
        } report: { update in
            outcomes.append(contentsOf: update.results)
        }

        #expect(outcomes.map(\.id) == [duplicate, cancelled, last])
        #expect(outcomes.map(\.state) == [.skipped, .cancelled, .completed])
    }
}
