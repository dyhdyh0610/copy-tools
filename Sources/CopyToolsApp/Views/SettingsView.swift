import CopyToolsCore
import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var confirmClearNonFavorites = false
    @State private var confirmClearAll = false
    private var language: AppLanguage {
        viewModel.settings.language
    }

    var body: some View {
        Form {
            Picker(L10n.text(.language, language), selection: $viewModel.settings.language) {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    Text(L10n.languageName(language)).tag(language)
                }
            }

            Picker(L10n.text(.retention, language), selection: $viewModel.settings.retentionPeriod) {
                ForEach(RetentionPeriod.allCases, id: \.self) { period in
                    Text(L10n.retentionName(period, language)).tag(period)
                }
            }

            Stepper(
                "\(L10n.text(.itemLimit, language)): \(viewModel.settings.itemLimit)",
                value: $viewModel.settings.itemLimit,
                in: 100...2000,
                step: 100
            )

            Toggle(L10n.text(.closePanelAfterCopy, language), isOn: $viewModel.settings.closePanelAfterCopy)
            Toggle(L10n.text(.hidePanelOnDeactivate, language), isOn: $viewModel.settings.hidesHistoryPanelOnDeactivate)

            Picker(L10n.text(.searchMode, language), selection: Binding(
                get: { viewModel.settings.searchMode },
                set: { viewModel.setSearchMode($0) }
            )) {
                ForEach(SearchMode.allCases, id: \.self) { mode in
                    Text(L10n.searchModeName(mode, language)).tag(mode)
                }
            }

            Toggle(L10n.text(.launchAtLogin, language), isOn: Binding(
                get: { viewModel.settings.launchAtLogin },
                set: { viewModel.setLaunchAtLogin($0) }
            ))
            .disabled(!viewModel.canConfigureLaunchAtLogin)

            if let message = viewModel.launchAtLoginMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if !viewModel.canConfigureLaunchAtLogin {
                Text(L10n.text(.launchAtLoginPackagedOnly, language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Toggle(L10n.text(.pauseRecording, language), isOn: $viewModel.settings.isRecordingPaused)
            Toggle(L10n.text(.cleanupFavorites, language), isOn: $viewModel.settings.cleanupFavorites)

            LabeledContent(L10n.text(.shortcut, language), value: viewModel.settings.shortcutDisplayName)

            Section(L10n.text(.history, language)) {
                Button(L10n.text(.clearNonFavorites, language)) {
                    confirmClearNonFavorites = true
                }

                Button(L10n.text(.clearAll, language), role: .destructive) {
                    confirmClearAll = true
                }
            }
        }
        .padding(20)
        .confirmationDialog(
            L10n.text(.clearNonFavoritesTitle, language),
            isPresented: $confirmClearNonFavorites,
            titleVisibility: .visible
        ) {
            Button(L10n.text(.clearNonFavorites, language), role: .destructive) {
                viewModel.clearNonFavorites()
            }
            Button(L10n.text(.cancel, language), role: .cancel) {}
        }
        .confirmationDialog(
            L10n.text(.clearAllTitle, language),
            isPresented: $confirmClearAll,
            titleVisibility: .visible
        ) {
            Button(L10n.text(.clearAll, language), role: .destructive) {
                viewModel.clearAll()
            }
            Button(L10n.text(.cancel, language), role: .cancel) {}
        }
    }
}
