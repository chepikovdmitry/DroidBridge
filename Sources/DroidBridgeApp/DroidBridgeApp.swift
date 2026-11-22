import AppKit
import SwiftUI
import UniformTypeIdentifiers

@main
struct DroidBridgeApp: App {
    @State private var model = BrowserModel()

    var body: some Scene {
        Window("DroidBridge", id: "browser") {
            BrowserWindow(model: model)
                .frame(minWidth: 850, minHeight: 560)
                .task { await model.start() }
        }
        .defaultSize(width: 1110, height: 740)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Выбрать папку на Mac…", action: model.chooseMacFolder)
                    .keyboardShortcut("o")
                Button("Обновить") { Task { await model.refresh() } }
                    .keyboardShortcut("r")
            }
        }
    }
}

private extension Color {
    static let bridgeAccent = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.44, green: 0.81, blue: 0.70, alpha: 1)
            : NSColor(red: 0.03, green: 0.40, blue: 0.34, alpha: 1)
    })
    static let bridgeBackground = Color(nsColor: .windowBackgroundColor)
    static let bridgeSurface = Color(nsColor: .controlBackgroundColor)
}

struct BrowserWindow: View {
    @Bindable var model: BrowserModel
    @State private var macDropTarget = false
    @State private var phoneDropTarget = false

    var body: some View {
        VStack(spacing: 18) {
            header
            HStack(spacing: 14) {
                macPanel
                copyActions
                phonePanel
            }
            TransferQueuePanel(model: model)
        }
        .padding(22)
        .background(Color.bridgeBackground)
        .tint(.bridgeAccent)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(Color(red: 0.04, green: 0.35, blue: 0.30), in: RoundedRectangle(cornerRadius: 13))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("DroidBridge").font(.system(size: 24, weight: .semibold))
                Text("Передача файлов по USB").font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 7) {
                Circle()
                    .fill(model.connection != nil ? Color.bridgeAccent : Color.secondary.opacity(0.55))
                    .frame(width: 7, height: 7)
                Text(model.connection != nil ? "USB подключён" : "USB не подключён")
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.quaternary.opacity(0.45), in: Capsule())
            Button {
                Task { await model.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise").frame(width: 24, height: 24)
            }
            .help("Обновить папки (⌘R)")
            .accessibilityLabel("Обновить папки")
        }
    }

    private var macPanel: some View {
        FilePanel(
            title: "Mac", subtitle: "Локальные файлы", icon: "desktopcomputer",
            path: model.macFolder.path(percentEncoded: false), items: model.macItems, selection: $model.macSelection,
            dropTarget: macDropTarget, error: model.macError, emptyReason: "В этой папке пока пусто.",
            loadingMessage: nil, loadingProgress: nil, canGoUp: model.macFolder.path != "/",
            goUp: { model.openMac(model.macFolder.deletingLastPathComponent()) },
            open: { item in
                if let url = item.localURL { model.openMac(url) }
            },
            drag: { item in
                let items = model.macSelection.contains(item.id) ? model.selectedMac : [item]
                return FileDrag(origin: nil, values: items.compactMap { $0.localURL?.path })
            }
        ) {
            Button(action: model.chooseMacFolder) {
                Label("Выбрать папку", systemImage: "folder")
                    .labelStyle(.titleAndIcon)
            }
            .controlSize(.small)
        }
        .dropDestination(for: FileDrag.self) { drops, _ in
            guard let folder = model.phoneFolder else { return false }
            let ids = drops.filter { $0.origin == folder }.flatMap(\.values)
            return model.download(ids: ids, from: folder)
        } isTargeted: { macDropTarget = $0 }
    }

    private var phonePanel: some View {
        FilePanel(
            title: "Android", subtitle: model.connection?.name ?? "USB-устройство", icon: "smartphone",
            path: model.phonePath.map(\.name).joined(separator: " / "),
            items: model.phoneItems, selection: $model.phoneSelection,
            dropTarget: phoneDropTarget && model.phoneFolder != nil, error: model.phoneError,
            emptyReason: model.connection == nil
                ? "Разблокируйте телефон и выберите на нём «Передача файлов»."
                : "В этой папке пока пусто.",
            loadingMessage: phoneLoadingMessage,
            loadingProgress: model.phoneEntryCount.map { "Загружено \(model.phoneItems.count) из \($0)" },
            canGoUp: model.phonePath.count > 1 && model.phoneNavigationAllowed,
            goUp: { Task { await model.phoneUp() } },
            open: { item in Task { await model.openPhone(item) } },
            drag: { item in
                let items = model.phoneSelection.contains(item.id) ? model.selectedPhone : [item]
                return FileDrag(origin: model.phoneFolder, values: items.map(\.id))
            },
            showPreviews: model.showPhonePreviews,
            preview: phonePreview
        ) {
            Toggle(isOn: $model.showPhonePreviews) {
                Label("Превью", systemImage: "photo")
            }
            .toggleStyle(.button)
            .controlSize(.small)
            .help("Показывать миниатюры фото и видео")
            Menu {
                if let storages = model.connection?.storages {
                    ForEach(storages) { storage in
                        Button(storage.name) { Task { await model.selectStorage(storage) } }
                    }
                    Divider()
                }
                Button("Подключить заново") { Task { await model.connect() } }
            } label: {
                Label("Устройство", systemImage: "externaldrive")
            }
            .controlSize(.small)
            .disabled(!model.phoneNavigationAllowed)
        }
        .dropDestination(for: FileDrag.self) { drops, _ in
            let urls = drops.filter { $0.origin == nil }.flatMap(\.values).map { URL(fileURLWithPath: $0) }
            return model.upload(urls)
        } isTargeted: { phoneDropTarget = $0 }
        .dropDestination(for: URL.self) { urls, _ in
            model.upload(urls)
        }
    }

    private func phonePreview(_ item: BrowserItem) -> FilePreview? {
        guard model.showPhonePreviews, let folder = model.phoneFolder, let entry = item.remote, !item.isFolder,
              let type = UTType(filenameExtension: (item.name as NSString).pathExtension),
              type.conforms(to: .image) || type.conforms(to: .movie) else { return nil }
        let date = entry.modifiedAt?.timeIntervalSince1970 ?? 0
        let key = "\(folder.connection):\(folder.storage):\(entry.id):\(entry.size):\(date):\(entry.name)"
        let canLoad = model.phoneNavigationAllowed && model.loadingPhoneFolder == nil
        return FilePreview(key: key, canLoad: canLoad) {
            try await model.loadPreview(for: item, in: folder, key: key)
        }
    }

    private var phoneLoadingMessage: String? {
        if model.phoneEntryCount != nil { return nil }
        if let folder = model.loadingPhoneFolder {
            return "Загружаем папку «\(folder)»…"
        }
        return model.connecting ? "Подключаем телефон…" : nil
    }

    private var copyActions: some View {
        VStack(spacing: 10) {
            Button {
                model.upload(model.selectedMac.compactMap(\.localURL))
            } label: {
                Image(systemName: "arrow.right").frame(width: 31, height: 27)
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.phoneFolder == nil || model.readingPhone || model.selectedMac.isEmpty)
            .accessibilityLabel("Копировать на Android")
            .help("Копировать выбранное на Android")

            Button {
                model.download(ids: model.selectedPhone.map(\.id))
            } label: {
                Image(systemName: "arrow.left").frame(width: 31, height: 27)
            }
            .disabled(model.readingPhone || model.selectedPhone.isEmpty)
            .accessibilityLabel("Копировать на Mac")
            .help("Копировать выбранное на Mac")
        }
        .font(.system(size: 14, weight: .semibold))
        .controlSize(.large)
    }

}

private struct TransferQueuePanel: View {
    let model: BrowserModel
    @State private var showTransfers = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 9) {
                Button {
                    showTransfers.toggle()
                } label: {
                    Label(
                        "Очередь передач",
                        systemImage: showTransfers ? "chevron.down" : "chevron.right"
                    )
                    .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.plain)
                let pending = model.pendingJobCount
                if pending > 0 {
                    Text(pending, format: .number)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Color.bridgeAccent)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.bridgeAccent.opacity(0.12), in: Capsule())
                }
                Spacer()
                if model.jobs.count > pending {
                    Button("Очистить завершённые", action: model.clearFinished)
                        .controlSize(.small)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 42)
            if let job = model.currentTransfer {
                Divider()
                row(for: job)
                    .background(Color.bridgeAccent.opacity(0.07))
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Текущая передача")
            }
            if let job = model.downloadConflict {
                Divider()
                HStack(spacing: 9) {
                    Text("Уже есть на Mac: \(job.source.name)")
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer(minLength: 4)
                    Button("Пропустить", action: { model.cancel(job.id) })
                    Button("Сохранить копию", action: { model.keepBoth(job.id) })
                    Button("Пропускать совпадения в пачке", action: { model.skipDownloadConflicts(job.id) })
                        .buttonStyle(.borderedProminent)
                }
                .controlSize(.small)
                .padding(.horizontal, 14)
                .frame(height: 36)
            }
            if showTransfers {
                Divider()
                if model.jobs.isEmpty {
                    Text("Выберите файлы в любой панели или перетащите их в соседнюю.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 14)
                        .frame(height: 45)
                } else {
                    List(model.jobs) { job in
                        row(for: job)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .environment(\.defaultMinListRowHeight, 0)
                    .frame(height: min(166, CGFloat(model.jobs.count * 56)))
                }
            }
        }
        .background(Color.bridgeSurface, in: RoundedRectangle(cornerRadius: 13))
        .overlay {
            RoundedRectangle(cornerRadius: 13)
                .strokeBorder(.quaternary)
                .allowsHitTesting(false)
        }
        .onChange(of: model.jobs.count) { old, new in
            if new > old { showTransfers = true }
        }
    }

    private func row(for job: TransferJob) -> some View {
        TransferRow(job: job, cancel: { model.cancel(job.id) }, keepBoth: { model.keepBoth(job.id) })
    }
}

struct FileDrag: Codable, Transferable {
    let origin: PhoneFolder?
    let values: [String]

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .droidBridgeSelection)
    }
}

private extension UTType {
    static let droidBridgeSelection = UTType(exportedAs: "app.droidbridge.selection")
}
