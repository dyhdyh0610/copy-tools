import AppKit
import CopyToolsCore
import SwiftUI
import UserNotifications

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var historyWindowController: HistoryWindowController?
    private var hotKeyManager: HotKeyManager?
    private var clipboardMonitor: ClipboardMonitor?
    private var historyViewModel: HistoryViewModel?
    private var firstLaunchWindowController: FirstLaunchWindowController?
    private var settingsWindowController: SettingsWindowController?

    private(set) var settingsViewModel: SettingsViewModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        do {
            let store = try HistoryStore(databaseURL: AppPaths.databaseURL)
            let settingsStore = SettingsStore(url: AppPaths.settingsURL)
            let settings = settingsStore.load()
            let settingsViewModel = SettingsViewModel(settings: settings, settingsStore: settingsStore)
            requestInitialPermissions(settingsViewModel: settingsViewModel)
            let historyViewModel = HistoryViewModel(store: store, settingsViewModel: settingsViewModel)
            settingsViewModel.clearNonFavoritesHandler = { [weak historyViewModel] in
                historyViewModel?.clearNonFavorites()
            }
            settingsViewModel.clearAllHandler = { [weak historyViewModel] in
                historyViewModel?.clearAll()
            }
            settingsViewModel.searchModeChangedHandler = { [weak historyViewModel] searchMode in
                historyViewModel?.applySearchModeFromSettings(searchMode)
            }

            self.settingsViewModel = settingsViewModel
            self.historyViewModel = historyViewModel
            self.historyWindowController = HistoryWindowController(viewModel: historyViewModel)
            self.settingsWindowController = SettingsWindowController(viewModel: settingsViewModel)
            historyViewModel.openSettingsHandler = { [weak self] in
                self?.showSettings()
            }
            self.statusBarController = StatusBarController(
                isPausedProvider: { settingsViewModel.settings.isRecordingPaused },
                languageProvider: { settingsViewModel.settings.language },
                openHistory: { [weak self] in self?.toggleHistoryPanel() },
                openSettings: { [weak self] in self?.showSettings() },
                toggleRecording: { settingsViewModel.toggleRecordingPaused() },
                quit: { NSApp.terminate(nil) }
            )

            let monitor = ClipboardMonitor(
                store: store,
                settingsProvider: { settingsViewModel.settings },
                imageDirectory: AppPaths.imageDirectory,
                notificationCenter: AppRuntime.isAppBundle ? UNUserNotificationCenter.current() : nil
            ) { [weak historyViewModel] in
                historyViewModel?.reload()
            }
            self.clipboardMonitor = monitor
            historyViewModel.copyHandler = { item in
                monitor.copy(item)
            }
            monitor.start()

            let hotKeyManager = HotKeyManager { [weak self] in
                Task { @MainActor in self?.toggleHistoryPanel() }
            }
            self.hotKeyManager = hotKeyManager
            do {
                try hotKeyManager.registerOptionC()
            } catch {
                historyViewModel.lastMessage = L10n.text(.shortcutUnavailableTitle, settingsViewModel.settings.language)
                showShortcutUnavailableAlert(language: settingsViewModel.settings.language)
            }

            historyViewModel.reload()
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(applicationDidResignActive),
                name: NSApplication.didResignActiveNotification,
                object: nil
            )
            if !settingsViewModel.settings.hasCompletedFirstLaunchGuide {
                let firstLaunchWindowController = FirstLaunchWindowController(viewModel: settingsViewModel)
                self.firstLaunchWindowController = firstLaunchWindowController
                firstLaunchWindowController.show()
            }
        } catch {
            NSAlert(error: error).runModal()
            NSApp.terminate(nil)
        }
    }

    private func toggleHistoryPanel() {
        statusBarController?.refresh()
        historyWindowController?.toggle()
    }

    private func showSettings() {
        statusBarController?.refresh()
        historyWindowController?.hide()
        settingsWindowController?.show()
    }

    @objc private func applicationDidResignActive() {
        historyWindowController?.hideIfNeededOnDeactivate()
    }

    private func requestInitialPermissions(settingsViewModel: SettingsViewModel) {
        if AppRuntime.isAppBundle {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }

        guard !AXIsProcessTrusted() else {
            return
        }

        guard !settingsViewModel.settings.hasPromptedForAccessibilityPermission else {
            return
        }

        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        settingsViewModel.settings.hasPromptedForAccessibilityPermission = true
    }

    private func showShortcutUnavailableAlert(language: AppLanguage) {
        let alert = NSAlert()
        alert.messageText = L10n.text(.shortcutUnavailableTitle, language)
        alert.informativeText = L10n.text(.shortcutUnavailableBody, language)
        alert.alertStyle = .warning
        alert.runModal()
    }
}
