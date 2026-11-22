import DroidBridgeCore
import SwiftUI

struct TransferRow: View {
    let job: TransferJob
    let cancel: () -> Void
    let keepBoth: () -> Void

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: job.source.toMac ? "arrow.left" : "arrow.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 20)
                .accessibilityLabel(job.source.toMac ? L10n.text("To Mac") : L10n.text("To Android"))
            VStack(alignment: .leading, spacing: 4) {
                Text(job.source.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(detail)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 10)
            switch job.state {
            case .copying, .waitingToCancel:
                if let fraction = job.progress {
                    ProgressView(value: fraction)
                        .frame(width: 92)
                        .accessibilityLabel(L10n.text("Transfer progress"))
                } else {
                    ProgressView().controlSize(.small)
                }
            case .completed:
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor)
            case .failed:
                Image(systemName: "exclamationmark.circle").foregroundStyle(.orange)
            case .conflict:
                Button(L10n.text("Skip"), action: cancel)
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                Button(L10n.text("Keep Both"), action: keepBoth)
                    .buttonStyle(.borderless)
                    .controlSize(.small)
            case .queued, .cancelled, .skipped:
                EmptyView()
            }

            if job.canCancel {
                if case .conflict = job.state {
                    EmptyView()
                } else {
                    Button(action: cancel) {
                        Image(systemName: "xmark.circle").imageScale(.medium)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.text("Cancel transfer"))
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 55)
        .help(detail)
        Divider().padding(.leading, 45)
    }

    private var detail: String {
        switch job.state {
        case .queued: L10n.text("Waiting to transfer")
        case .copying: job.currentName.map { L10n.text("Copying: %@", $0) } ?? L10n.text("Preparing to copy")
        case .waitingToCancel: L10n.text("Cancelling after the current USB operation finishes")
        case .conflict: L10n.text("This name already exists in the destination")
        case .completed: L10n.text("Copied")
        case .skipped: L10n.text("Skipped: name already exists")
        case .cancelled: L10n.text("Cancelled")
        case .failed(let message): message
        }
    }
}
