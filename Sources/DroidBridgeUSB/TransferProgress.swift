import Darwin
import Dispatch
import Foundation
import Synchronization

private final class Cancellation: Sendable {
    let requested = Atomic(false)
}

private final class TerminalProgress {
    private var lastPercent = -1

    func report(_ sent: UInt64, _ total: UInt64) {
        guard total > 0 else { return }
        let percent = Int(Double(min(sent, total)) / Double(total) * 100)
        guard percent > lastPercent else { return }
        lastPercent = percent
        writeError("\rTransferring… \(percent)%")
    }

    func finish() {
        if lastPercent >= 0 { writeError("\n") }
    }
}

func withTransferProgress<Result>(
    discardOnCancellation: Bool = false,
    _ transfer: (@escaping (UInt64, UInt64) -> Void, () -> Bool) throws -> Result
) rethrows -> Result {
    let progress = TerminalProgress()
    let cancellation = Cancellation()
    let interrupt = DispatchSource.makeSignalSource(signal: SIGINT, queue: .global())
    let previous = signal(SIGINT, SIG_IGN)
    interrupt.setEventHandler {
        guard !cancellation.requested.exchange(true, ordering: .relaxed) else { return }
        if discardOnCancellation {
            writeError("\nCancellation requested. The download will be discarded after USB transfer finishes.\n")
        } else {
            writeError("\nThe upload has started and will finish before the session closes.\n")
        }
    }
    interrupt.activate()
    defer {
        interrupt.cancel()
        signal(SIGINT, previous)
        progress.finish()
    }
    return try transfer(progress.report) { cancellation.requested.load(ordering: .relaxed) }
}

func writeError(_ text: String) {
    try? FileHandle.standardError.write(contentsOf: Data(text.utf8))
}
