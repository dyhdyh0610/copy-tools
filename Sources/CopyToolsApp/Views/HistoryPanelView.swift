import CopyToolsCore
import SwiftUI

struct HistoryPanelView: View {
    @ObservedObject var viewModel: HistoryViewModel
    @FocusState private var searchFocused: Bool
    @FocusState private var titleFocused: Bool
    @State private var confirmBatchDelete = false
    private var language: AppLanguage {
        viewModel.settingsViewModel.settings.language
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            HStack(spacing: 0) {
                list
                    .frame(width: 430)

                Divider()

                detail
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            footer
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            searchFocused = true
            viewModel.reload()
        }
        .onKeyPress(.downArrow) {
            viewModel.selectNext()
            return .handled
        }
        .onKeyPress(.upArrow) {
            viewModel.selectPrevious()
            return .handled
        }
        .onKeyPress(.return) {
            if titleFocused {
                titleFocused = false
                searchFocused = true
                return .handled
            }

            if searchFocused {
                return .ignored
            }

            return .handled
        }
        .onKeyPress(.delete) {
            if let item = viewModel.selectedItem {
                viewModel.delete(item)
            }
            return .handled
        }
        .confirmationDialog(
            L10n.text(.deleteSelectedTitle, language),
            isPresented: $confirmBatchDelete,
            titleVisibility: .visible
        ) {
            Button("\(L10n.text(.deleteItems, language)) (\(viewModel.selectedIDs.count))", role: .destructive) {
                viewModel.deleteSelected()
            }
            Button(L10n.text(.cancel, language), role: .cancel) {}
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "doc.on.clipboard")
                TextField(L10n.text(.search, language), text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .focused($searchFocused)
                    .font(.system(size: 18))

                Picker(L10n.text(.searchMode, language), selection: $viewModel.searchMode) {
                    ForEach(SearchMode.allCases, id: \.self) { mode in
                        Text(L10n.searchModeName(mode, language)).tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 128)

                if viewModel.settingsViewModel.settings.isRecordingPaused {
                    Text(L10n.text(.paused, language))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.yellow.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                Button {
                    viewModel.openSettings()
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
                .help(L10n.text(.openSettings, language))
            }

            Picker("Filter", selection: $viewModel.filter) {
                ForEach(HistoryFilter.allCases) { filter in
                    Text(filter.title(language: language)).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            if !viewModel.sourceApps.isEmpty {
                Picker(L10n.text(.sourceApp, language), selection: sourceBinding) {
                    Text(L10n.text(.allApps, language)).tag(Optional<String>.none)
                    ForEach(viewModel.sourceApps) { app in
                        Text("\(app.name) (\(app.itemCount))").tag(Optional(app.bundleIdentifier))
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .padding(16)
    }

    private var sourceBinding: Binding<String?> {
        Binding(
            get: { viewModel.selectedSourceBundleIdentifier },
            set: { viewModel.selectedSourceBundleIdentifier = $0 }
        )
    }

    private var list: some View {
        List(viewModel.items, selection: $viewModel.selectedItemID) { item in
            HistoryItemRow(
                item: item,
                language: language,
                isSelected: item.id == viewModel.selectedItemID,
                selectionMode: viewModel.selectionMode,
                selectedIDs: $viewModel.selectedIDs,
                select: { viewModel.selectedItemID = item.id },
                copy: { viewModel.copy(item) },
                favorite: { viewModel.toggleFavorite(item) },
                delete: { viewModel.delete(item) }
            )
            .tag(item.id)
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private var detail: some View {
        if let item = viewModel.selectedItem {
            ClipboardDetailView(
                item: item,
                language: language,
                title: Binding(
                    get: { viewModel.selectedItem?.title ?? "" },
                    set: { newTitle in
                        guard let selected = viewModel.selectedItem else {
                            return
                        }
                        viewModel.updateTitle(newTitle, for: selected)
                    }
                ),
                titleFocused: $titleFocused
            ) {
                viewModel.copy(item)
            } favorite: {
                viewModel.toggleFavorite(item)
            }
            .padding(18)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "tray")
                    .font(.system(size: 36))
                Text(L10n.text(.noHistory, language))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var footer: some View {
        HStack {
            if let message = viewModel.lastMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if message == L10n.text(.deletedUndo, language) {
                    Button(L10n.text(.undo, language)) { viewModel.undoDelete() }
                        .buttonStyle(.borderless)
                }
            }

            Spacer()

            Toggle(L10n.text(.select, language), isOn: $viewModel.selectionMode)
                .toggleStyle(.checkbox)

            if viewModel.selectionMode {
                Button(L10n.text(.deleteSelected, language)) {
                    confirmBatchDelete = true
                }
                .disabled(viewModel.selectedIDs.isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
