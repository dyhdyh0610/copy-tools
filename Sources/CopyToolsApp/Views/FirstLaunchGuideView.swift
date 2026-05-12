import CopyToolsCore
import SwiftUI

struct FirstLaunchGuideView: View {
    @ObservedObject var viewModel: SettingsViewModel
    let close: () -> Void
    private var language: AppLanguage {
        viewModel.settings.language
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Copy Tools")
                    .font(.system(size: 28, weight: .semibold))
                Text(L10n.text(.localSaveNote, language))
                    .foregroundStyle(.secondary)
            }

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

                LabeledContent(L10n.text(.shortcut, language), value: viewModel.settings.shortcutDisplayName)
            }
            .formStyle(.grouped)

            Spacer()

            HStack {
                Spacer()
                Button(L10n.text(.startUsing, language)) {
                    viewModel.completeFirstLaunchGuide()
                    close()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(24)
        .frame(width: 460, height: 420)
    }
}
