import Foundation

struct DownloadResult: Sendable {
    let id: UUID
    let state: TransferJob.State
    let destination: URL?
}

struct DownloadProgress: Sendable {
    let id: UUID
    let name: String?
    let fraction: Double?
}

struct DownloadReport: Sendable {
    let results: [DownloadResult]
    let current: DownloadProgress?
}

// Reporting never waits for the consumer. The USB worker owns the next-file decision.
func runDownloads<Request>(
    _ requests: [Request],
    id: (Request) -> UUID,
    skipConflicts: Bool,
    transfer: (Request, @escaping (String, Double?) -> Void) throws -> URL,
    report: @escaping (DownloadReport) -> Void
) {
    var results: [DownloadResult] = []
    var nextReport = ContinuousClock.now

    func publish(_ current: DownloadProgress? = nil, force: Bool = false) {
        let now = ContinuousClock.now
        guard (force || now >= nextReport), !results.isEmpty || current != nil else { return }
        report(DownloadReport(results: results, current: current))
        results.removeAll(keepingCapacity: true)
        nextReport = now.advanced(by: .milliseconds(350))
    }

    for request in requests {
        let jobID = id(request)
        publish(DownloadProgress(id: jobID, name: nil, fraction: nil))
        let state: TransferJob.State
        var destination: URL?
        do {
            destination = try transfer(request) { name, fraction in
                publish(DownloadProgress(id: jobID, name: name, fraction: fraction))
            }
            state = .completed
        } catch is CancellationError {
            state = .cancelled
        } catch is TransferConflict {
            state = skipConflicts ? .skipped : .conflict
        } catch {
            state = .failed(error.localizedDescription)
        }
        results.append(DownloadResult(id: jobID, state: state, destination: destination))
        if state == .conflict {
            publish(force: true)
            return
        }
    }
    publish(force: true)
}
