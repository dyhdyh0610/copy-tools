import CopyToolsCore
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings {
        didSet { save() }
    }
    @Published var launchAtLoginMessage: String?

    var clearNonFavoritesHandler: (() -> Void)?
    var clearAllHandler: (() -> Void)?
    var searchModeChangedHandler: ((SearchMode) -> Void)?

    private let settingsStore: SettingsStore

    init(settings: AppSettings, settingsStore: SettingsStore) {
        var settings = settings
        if LaunchAtLoginManager.isAvailable {
            settings.launchAtLogin = LaunchAtLoginManager.isEnabled
        }
        self.settings = settings
        self.settingsStore = settingsStore
    }

    func toggleRecordingPaused() {
        settings.isRecordingPaused.toggle()
    }

    func completeFirstLaunchGuide() {
        settings.hasCompletedFirstLaunchGuide = true
    }

    func clearNonFavorites() {
        clearNonFavoritesHandler?()
    }

    func clearAll() {
        clearAllHandler?()
    }

    var canConfigureLaunchAtLogin: Bool {
        LaunchAtLoginManager.isAvailable
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try LaunchAtLoginManager.setEnabled(enabled)
            settings.launchAtLogin = LaunchAtLoginManager.isEnabled
            launchAtLoginMessage = enabled && !settings.launchAtLogin
                ? L10n.text(.launchAtLoginPackagedOnly, settings.language)
                : nil
        } catch {
            settings.launchAtLogin = LaunchAtLoginManager.isEnabled
            launchAtLoginMessage = L10n.text(.launchAtLoginFailed, settings.language)
        }
    }

    func setSearchMode(_ searchMode: SearchMode) {
        settings.searchMode = searchMode
        searchModeChangedHandler?(searchMode)
    }

    private func save() {
        try? settingsStore.save(settings)
    }
}
