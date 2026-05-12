import CopyToolsCore
import AppKit
import SwiftUI

struct ClipboardDetailView: View {
    let item: ClipboardItem
    let language: AppLanguage
    @Binding var title: String
    var titleFocused: FocusState<Bool>.Binding
    let copy: () -> Void
    let favorite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(item.kind == .text ? L10n.text(.text, language) : L10n.text(.image, language), systemImage: item.kind == .text ? "text.alignleft" : "photo")
                    .font(.headline)

                Spacer()

                Button(action: favorite) {
                    Image(systemName: item.isFavorite ? "star.fill" : "star")
                }

                Button(action: copy) {
                    Label(L10n.text(.copy, language), systemImage: "doc.on.doc")
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.text(.recordTitle, language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField(L10n.text(.titlePlaceholder, language), text: $title)
                    .textFieldStyle(.roundedBorder)
                    .focused(titleFocused)
                    .onSubmit {
                        titleFocused.wrappedValue = false
                    }
            }

            Group {
                switch item.kind {
                case .text:
                    ScrollView {
                        Text(item.text ?? "")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .font(.system(size: 14, design: .monospaced))
                    }
                case .image:
                    if let path = item.imagePath, let image = NSImage(contentsOfFile: path) {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Text(L10n.text(.imagePreviewUnavailable, language))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text(item.sourceAppName ?? L10n.text(.unknownApp, language))
                Text(item.updatedAt.formatted(date: .abbreviated, time: .standard))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}
