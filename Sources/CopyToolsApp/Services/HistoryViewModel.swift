import CopyToolsCore
import Foundation

enum HistoryFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case favorites = "Favorites"
    case text = "Text"
    case images = "Images"

    var id: String { rawValue }

    func title(language: AppLanguage) -> String {
        switch self {
        case .all:
            return L10n.text(.all, language)
        case .favorites:
            return L10n.text(.favorites, language)
        case .text:
            return L10n.text(.text, language)
        case .images:
            return L10n.text(.images, language)
        }
    }
}

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var items: [ClipboardItem] = []
    @Published var selectedItemID: ClipboardItem.ID?
    @Published var searchText = "" {
        didSet { reload() }
    }
    @Published var filter: HistoryFilter = .all {
        didSet { reload() }
    }
    @Published var selectionMode = false
    @Published var selectedIDs = Set<ClipboardItem.ID>()
    @Published var lastMessage: String?
    @Published var sourceApps: [SourceApp] = []
    @Published var selectedSourceBundleIdentifier: String? {
        didSet { reload() }
    }
    @Published var searchMode: SearchMode {
        didSet {
            settingsViewModel.setSearchMode(searchMode)
            reload()
        }
    }

    let settingsViewModel: SettingsViewModel
    var copyHandler: ((ClipboardItem) -> Void)?
    var onCopyCompleted: (() -> Void)?
    var openSettingsHandler: (() -> Void)?

    private let store: HistoryStore
    private var recentlyDeleted: ClipboardItem?
    private var language: AppLanguage {
        settingsViewModel.settings.language
    }

    init(store: HistoryStore, settingsViewModel: SettingsViewModel) {
        self.store = store
        self.settingsViewModel = settingsViewModel
        self.searchMode = settingsViewModel.settings.searchMode
    }

    var selectedItem: ClipboardItem? {
        guard let selectedItemID else {
            return items.first
        }
        return items.first { $0.id == selectedItemID }
    }

    func reload() {
        let kind: ClipboardItemKind? = switch filter {
        case .all, .favorites:
            nil
        case .images:
            .image
        case .text:
            .text
        }

        do {
            items = try store.items(
                search: searchText,
                searchMode: searchMode,
                kind: kind,
                favoritesOnly: filter == .favorites,
                sourceBundleIdentifier: selectedSourceBundleIdentifier,
                limit: settingsViewModel.settings.itemLimit
            )
            sourceApps = try store.sourceApps()
            if selectedItemID == nil || !items.contains(where: { $0.id == selectedItemID }) {
                selectedItemID = items.first?.id
            }
        } catch {
            lastMessage = L10n.text(.loadFailed, language)
        }
    }

    func copy(_ item: ClipboardItem) {
        copyHandler?(item)
        lastMessage = L10n.text(.copied, language)
        onCopyCompleted?()
    }

    func toggleFavorite(_ item: ClipboardItem) {
        do {
            try store.setFavorite(!item.isFavorite, for: item.id)
            reload()
        } catch {
            lastMessage = L10n.text(.favoriteFailed, language)
        }
    }

    func updateTitle(_ title: String, for item: ClipboardItem) {
        do {
            try store.setTitle(title, for: item.id)
            reload()
        } catch {
            lastMessage = L10n.text(.favoriteFailed, language)
        }
    }

    func openSettings() {
        openSettingsHandler?()
    }

    func applySearchModeFromSettings(_ searchMode: SearchMode) {
        guard self.searchMode != searchMode else {
            return
        }
        self.searchMode = searchMode
    }

    func delete(_ item: ClipboardItem) {
        do {
            recentlyDeleted = item
            try store.delete(id: item.id)
            lastMessage = L10n.text(.deletedUndo, language)
            reload()
            clearUndoAfterDelay(item.id)
        } catch {
            lastMessage = L10n.text(.deleteFailed, language)
        }
    }

    func undoDelete() {
        guard let recentlyDeleted else {
            return
        }

        do {
            try store.upsert(recentlyDeleted)
            self.recentlyDeleted = nil
            lastMessage = L10n.text(.restored, language)
            reload()
        } catch {
            lastMessage = L10n.text(.restoreFailed, language)
        }
    }

    func deleteSelected() {
        guard !selectedIDs.isEmpty else {
            return
        }

        do {
            try store.delete(ids: Array(selectedIDs))
            selectedIDs.removeAll()
            selectionMode = false
            lastMessage = L10n.text(.selectedDeleted, language)
            reload()
        } catch {
            lastMessage = L10n.text(.deleteFailed, language)
        }
    }

    func clearNonFavorites() {
        do {
            try store.clearNonFavorites()
            reload()
        } catch {
            lastMessage = L10n.text(.clearFailed, language)
        }
    }

    func clearAll() {
        do {
            try store.clearAll()
            reload()
        } catch {
            lastMessage = L10n.text(.clearFailed, language)
        }
    }

    func resetSourceFilter() {
        selectedSourceBundleIdentifier = nil
    }

    func selectNext() {
        moveSelection(offset: 1)
    }

    func selectPrevious() {
        moveSelection(offset: -1)
    }

    private func moveSelection(offset: Int) {
        guard !items.isEmpty else {
            selectedItemID = nil
            return
        }

        let currentIndex = selectedItemID.flatMap { id in items.firstIndex { $0.id == id } } ?? 0
        let nextIndex = min(max(currentIndex + offset, 0), items.count - 1)
        selectedItemID = items[nextIndex].id
    }

    private func clearUndoAfterDelay(_ id: UUID) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            if recentlyDeleted?.id == id {
                recentlyDeleted = nil
            }
        }
    }
}
