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
                .accessibilityLabel(job.source.toMac ? "На Mac" : "На Android")
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
                        .accessibilityLabel("Прогресс передачи")
                } else {
                    ProgressView().controlSize(.small)
                }
            case .completed:
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor)
            case .failed:
                Image(systemName: "exclamationmark.circle").foregroundStyle(.orange)
            case .conflict:
                Button("Пропустить", action: cancel)
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                Button("Сохранить копию", action: keepBoth)
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
                    .accessibilityLabel("Отменить передачу")
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
        case .queued: "Ожидает передачи"
        case .copying: job.currentName.map { "Копируется: \($0)" } ?? "Подготовка к копированию"
        case .waitingToCancel: "Отмена после завершения текущего обмена по USB"
        case .conflict: "Это имя уже занято в папке назначения"
        case .completed: "Скопировано"
        case .skipped: "Пропущено: имя уже занято"
        case .cancelled: "Отменено"
        case .failed(let message): message
        }
    }
}
