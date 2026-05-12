import AppKit
import CopyToolsCore

@MainActor
final class StatusBarController {
    private let statusItem: NSStatusItem
    private let isPausedProvider: () -> Bool
    private let languageProvider: () -> AppLanguage
    private let openHistory: () -> Void
    private let openSettings: () -> Void
    private let toggleRecording: () -> Void
    private let quit: () -> Void

    init(
        isPausedProvider: @escaping () -> Bool,
        languageProvider: @escaping () -> AppLanguage,
        openHistory: @escaping () -> Void,
        openSettings: @escaping () -> Void,
        toggleRecording: @escaping () -> Void,
        quit: @escaping () -> Void
    ) {
        self.isPausedProvider = isPausedProvider
        self.languageProvider = languageProvider
        self.openHistory = openHistory
        self.openSettings = openSettings
        self.toggleRecording = toggleRecording
        self.quit = quit
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        statusItem.button?.target = self
        statusItem.button?.action = #selector(openHistoryFromMenuBar)
        refresh()
    }

    func refresh() {
        let language = languageProvider()
        statusItem.button?.title = isPausedProvider() ? "CT \(L10n.text(.paused, language))" : "CT"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: L10n.text(.openHistory, language), action: #selector(openHistoryFromMenu), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: isPausedProvider() ? L10n.text(.resumeRecording, language) : L10n.text(.pauseRecordingMenu, language), action: #selector(toggleRecordingFromMenu), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: L10n.text(.settings, language), action: #selector(openSettingsFromMenu), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: L10n.text(.quit, language), action: #selector(quitFromMenu), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }
        statusItem.menu = menu
    }

    @objc private func openHistoryFromMenuBar() {
        openHistory()
    }

    @objc private func openHistoryFromMenu() {
        openHistory()
    }

    @objc private func openSettingsFromMenu() {
        openSettings()
    }

    @objc private func toggleRecordingFromMenu() {
        toggleRecording()
        refresh()
    }

    @objc private func quitFromMenu() {
        quit()
    }
}
