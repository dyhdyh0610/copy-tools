import AppKit
import SwiftUI

@MainActor
final class FirstLaunchWindowController {
    private let window: NSWindow

    init(viewModel: SettingsViewModel) {
        self.window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.text(.setupTitle, viewModel.settings.language)
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: FirstLaunchGuideView(viewModel: viewModel) { [weak window] in
            window?.close()
        })
    }

    func show() {
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
