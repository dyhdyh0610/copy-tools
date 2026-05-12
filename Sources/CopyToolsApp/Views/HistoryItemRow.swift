import CopyToolsCore
import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct HistoryItemRow: View {
    let item: ClipboardItem
    let language: AppLanguage
    let isSelected: Bool
    let selectionMode: Bool
    @Binding var selectedIDs: Set<ClipboardItem.ID>
    let select: () -> Void
    let copy: () -> Void
    let favorite: () -> Void
    let delete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            if selectionMode {
                Toggle("", isOn: Binding(
                    get: { selectedIDs.contains(item.id) },
                    set: { checked in
                        if checked {
                            selectedIDs.insert(item.id)
                        } else {
                            selectedIDs.remove(item.id)
                        }
                    }
                ))
                .labelsHidden()
            }

            preview

            VStack(alignment: .leading, spacing: 4) {
                if let title = item.title, !title.isEmpty {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                }

                Text(primaryText)
                    .lineLimit(3)
                    .font(.system(size: 13))

                HStack(spacing: 6) {
                    Text(item.sourceAppName ?? L10n.text(.unknownApp, language))
                    Text(item.updatedAt.formatted(date: .abbreviated, time: .shortened))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: favorite) {
                Image(systemName: item.isFavorite ? "star.fill" : "star")
            }
            .buttonStyle(.borderless)

            Button(action: copy) {
                Image(systemName: "doc.on.doc")
            }
            .buttonStyle(.borderless)

            Button(role: .destructive, action: delete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            select()
        }
        .padding(.vertical, 6)
        .onDrag {
            guard item.kind == .image,
                  let path = item.imagePath else {
                return NSItemProvider(object: primaryText as NSString)
            }
            return NSItemProvider(contentsOf: URL(fileURLWithPath: path)) ?? NSItemProvider()
        }
    }

    @ViewBuilder
    private var preview: some View {
        switch item.kind {
        case .text:
            Image(systemName: "text.alignleft")
                .frame(width: 44, height: 44)
                .background(Color.secondary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        case .image:
            if let path = item.thumbnailPath, let image = NSImage(contentsOfFile: path) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "photo")
                    .frame(width: 96, height: 96)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var primaryText: String {
        switch item.kind {
        case .text:
            return item.text ?? ""
        case .image:
            return L10n.text(.image, language)
        }
    }
}
