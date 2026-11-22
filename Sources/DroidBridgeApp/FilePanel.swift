import SwiftUI

private enum FileColumn: CaseIterable {
    case name, type, size, date

    var heading: String {
        switch self {
        case .name: "Имя"
        case .type: "Тип"
        case .size: "Размер"
        case .date: "Изменён"
        }
    }

    var width: CGFloat? {
        switch self {
        case .name: nil
        case .type: 57
        case .size: 73
        case .date: 110
        }
    }

    var alignment: Alignment { self == .size ? .trailing : .leading }
}

private extension BrowserItem {
    var typeName: String {
        if isFolder { return "Папка" }
        let ext = (name as NSString).pathExtension
        return ext.isEmpty ? "Файл" : ext.uppercased()
    }
}

struct FilePreview {
    let key: String
    let canLoad: Bool
    let load: () async throws -> CGImage?
}

struct FilePanel<Trailing: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let path: String
    let items: [BrowserItem]
    @Binding var selection: Set<String>
    let dropTarget: Bool
    let error: String?
    let emptyReason: String
    let loadingMessage: String?
    let loadingProgress: String?
    let canGoUp: Bool
    let goUp: () -> Void
    let open: (BrowserItem) -> Void
    let drag: (BrowserItem) -> FileDrag
    var showPreviews = false
    var preview: ((BrowserItem) -> FilePreview?)?
    @ViewBuilder var trailing: () -> Trailing
    @State private var sortColumn: FileColumn = .name
    @State private var ascending = true
    @State private var sortedItems: [BrowserItem] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 34, height: 34)
                    .background(Color.accentColor.opacity(0.11), in: RoundedRectangle(cornerRadius: 9))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer(minLength: 4)
                trailing()
            }
            .padding(13)

            HStack(spacing: 9) {
                Button(action: goUp) {
                    Image(systemName: "arrow.up")
                        .frame(width: 19, height: 17)
                }
                .disabled(!canGoUp)
                .accessibilityLabel("На уровень выше")
                .help("На уровень выше")
                Text(path.isEmpty ? "Хранилище" : path)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(path)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(.quaternary.opacity(0.28))

            Divider()
            HStack(spacing: 9) {
                ForEach(FileColumn.allCases, id: \.self) { column in
                    columnHeading(column)
                }
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .frame(height: 29)

            Divider()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let error, !items.isEmpty {
                Label(error, systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .lineLimit(2)
                    .help(error)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
            }
            Divider()
            HStack {
                if let loadingProgress {
                    ProgressView().controlSize(.mini).accessibilityHidden(true)
                    Text(loadingProgress)
                } else {
                    Text("Объектов \(items.count.formatted())")
                }
                Spacer()
                if !selection.isEmpty {
                    Text("Выбрано \(selection.count.formatted())")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 13)
            .frame(height: 30)
        }
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 13))
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .overlay {
            RoundedRectangle(cornerRadius: 13)
                .strokeBorder(
                    dropTarget ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary),
                    lineWidth: dropTarget ? 2 : 1
                )
                .allowsHitTesting(false)
        }
        .onChange(of: items, initial: true) { _, _ in sortItems() }
    }

    @ViewBuilder
    private var content: some View {
        if let loadingMessage {
            VStack(spacing: 11) {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityHidden(true)
                Text(loadingMessage)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
        } else if items.isEmpty {
            VStack(spacing: 11) {
                Image(systemName: error == nil ? icon : "exclamationmark.circle")
                    .font(.system(size: 27, weight: .light))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                if let error {
                    Text(error)
                        .font(.subheadline)
                        .textSelection(.enabled)
                } else {
                    Text(emptyReason).font(.subheadline)
                }
            }
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            .frame(maxWidth: 285)
            .padding(16)
        } else {
            List(sortedItems, selection: $selection) { item in
                FileRow(item: item, showPreviews: showPreviews, preview: preview?(item))
                    .tag(item.id)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    .contentShape(Rectangle())
                    .draggable(drag(item))
                    .accessibilityAction(named: Text("Открыть папку")) {
                        if item.isFolder { open(item) }
                    }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .contextMenu(forSelectionType: String.self) { ids in
                if let folder = selectedFolder(in: ids) {
                    Button("Открыть папку") { open(folder) }
                }
            } primaryAction: { ids in
                if let folder = selectedFolder(in: ids) {
                    open(folder)
                }
            }
            .id(path)
        }
    }

    private func selectedFolder(in ids: Set<String>) -> BrowserItem? {
        guard ids.count == 1, let id = ids.first else { return nil }
        return items.first { $0.id == id && $0.isFolder }
    }

    private func columnHeading(_ column: FileColumn) -> some View {
        Button {
            if sortColumn == column {
                ascending.toggle()
            } else {
                sortColumn = column
                ascending = column == .name || column == .type
            }
            sortItems()
        } label: {
            HStack(spacing: 4) {
                Text(column.heading)
                if sortColumn == column {
                    Image(systemName: ascending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8, weight: .semibold))
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, alignment: column.alignment)
            .frame(width: column.width)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(sortColumn == column ? (ascending ? "По возрастанию" : "По убыванию") : "")
        .help("Сортировать по столбцу «\(column.heading)»")
    }

    private func sortItems() {
        sortedItems = items.sorted(by: precedes)
    }

    private func precedes(_ lhs: BrowserItem, _ rhs: BrowserItem) -> Bool {
        if lhs.isFolder != rhs.isFolder { return lhs.isFolder }
        let byName = lhs.name.localizedStandardCompare(rhs.name)
        switch sortColumn {
        case .name:
            if byName != .orderedSame {
                return byName == (ascending ? .orderedAscending : .orderedDescending)
            }
        case .type:
            let comparison = lhs.typeName.localizedStandardCompare(rhs.typeName)
            if comparison != .orderedSame {
                return comparison == (ascending ? .orderedAscending : .orderedDescending)
            }
        case .size:
            if !lhs.isFolder, let order = orderIfDifferent(lhs.size, rhs.size) { return order }
        case .date:
            if let order = orderIfDifferent(lhs.modifiedAt, rhs.modifiedAt) { return order }
        }
        if byName != .orderedSame { return byName == .orderedAscending }
        return lhs.id < rhs.id
    }

    private func orderIfDifferent<Value: Comparable>(_ lhs: Value?, _ rhs: Value?) -> Bool? {
        switch (lhs, rhs) {
        case let (left?, right?) where left != right: ascending ? left < right : left > right
        case (_?, nil): true
        case (nil, _?): false
        default: nil
        }
    }
}

private struct FileRow: View {
    let item: BrowserItem
    let showPreviews: Bool
    let preview: FilePreview?
    @State private var visible = false
    @State private var loaded: (key: String, image: CGImage)?

    var body: some View {
        HStack(spacing: 9) {
            HStack(spacing: 8) {
                thumbnailOrIcon
                Text(item.name)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(item.typeName)
                .lineLimit(1)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: FileColumn.type.width, alignment: .leading)

            let bytes = item.isFolder ? nil : item.size
            Text(bytes.map { Int64(clamping: $0).formatted(.byteCount(style: .file)) } ?? "—")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: FileColumn.size.width, alignment: .trailing)

            Group {
                if let date = item.modifiedAt {
                    Text(date, format: .dateTime.day().month(.twoDigits).year(.twoDigits).hour().minute())
                        .help(date.formatted(date: .complete, time: .standard))
                } else {
                    Text("—")
                }
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .frame(width: FileColumn.date.width, alignment: .leading)
        }
        .font(.system(size: 13))
        .frame(minHeight: showPreviews ? 36 : 26)
        .help(item.name)
        .background {
            if showPreviews { ThumbnailViewport { visible = $0 } }
        }
        .onChange(of: showPreviews) { _, enabled in
            if !enabled { visible = false }
        }
        .onDisappear { visible = false }
        .task(id: visible && preview?.canLoad == true ? preview?.key : nil) {
            guard visible, let preview, preview.canLoad, loaded?.key != preview.key,
                  let image = try? await preview.load(), !Task.isCancelled else { return }
            loaded = (preview.key, image)
        }
    }

    private var thumbnailOrIcon: some View {
        Group {
            if showPreviews, let loaded, loaded.key == preview?.key {
                Image(decorative: loaded.image, scale: 1)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            } else {
                Image(systemName: item.isFolder ? "folder.fill" : "doc")
                    .foregroundStyle(item.isFolder ? Color.accentColor : Color.secondary)
            }
        }
        .frame(width: showPreviews ? 40 : 17, height: showPreviews ? 30 : nil)
        .accessibilityHidden(true)
    }
}
