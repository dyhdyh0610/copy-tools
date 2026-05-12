import AppKit
import SwiftUI

@MainActor
final class HistoryWindowController {
    private let panel: NSPanel
    private let viewModel: HistoryViewModel

    init(viewModel: HistoryViewModel) {
        self.viewModel = viewModel
        self.panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 560),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(rootView: HistoryPanelView(viewModel: viewModel))

        viewModel.onCopyCompleted = { [weak self, weak viewModel] in
            guard viewModel?.settingsViewModel.settings.closePanelAfterCopy == true else {
                return
            }
            self?.hide()
        }
    }

    func toggle() {
        if panel.isVisible && NSApp.isActive && panel.isKeyWindow {
            hide()
        } else {
            show()
        }
    }

    func show() {
        viewModel.reload()
        centerNearActiveScreen()
        NSApp.activate(ignoringOtherApps: true)
        panel.orderFrontRegardless()
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel.orderOut(nil)
    }

    func hideIfNeededOnDeactivate() {
        guard viewModel.settingsViewModel.settings.hidesHistoryPanelOnDeactivate else {
            return
        }
        hide()
    }

    private func centerNearActiveScreen() {
        let screen = NSScreen.main ?? NSScreen.screens.first
        guard let frame = screen?.visibleFrame else {
            panel.center()
            return
        }
        let size = panel.frame.size
        let origin = NSPoint(
            x: frame.midX - size.width / 2,
            y: frame.maxY - size.height - 90
        )
        panel.setFrameOrigin(origin)
    }
}
