import AppKit
import CopyToolsCore
import Foundation
import UserNotifications

@MainActor
final class ClipboardMonitor {
    private let pasteboard = NSPasteboard.general
    private let store: HistoryStore
    private let settingsProvider: () -> AppSettings
    private let imageDirectory: URL
    private let notificationCenter: UNUserNotificationCenter?
    private let onChange: () -> Void

    private var timer: Timer?
    private var lastChangeCount: Int
    private var isWritingToPasteboard = false

    init(
        store: HistoryStore,
        settingsProvider: @escaping () -> AppSettings,
        imageDirectory: URL,
        notificationCenter: UNUserNotificationCenter?,
        onChange: @escaping () -> Void
    ) {
        self.store = store
        self.settingsProvider = settingsProvider
        self.imageDirectory = imageDirectory
        self.notificationCenter = notificationCenter
        self.onChange = onChange
        self.lastChangeCount = pasteboard.changeCount
    }

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func copy(_ item: ClipboardItem) {
        isWritingToPasteboard = true
        pasteboard.clearContents()

        switch item.kind {
        case .text:
            if let text = item.text {
                pasteboard.setString(text, forType: .string)
            }
        case .image:
            if let imagePath = item.imagePath, let image = NSImage(contentsOfFile: imagePath) {
                pasteboard.writeObjects([image])
            }
        }

        lastChangeCount = pasteboard.changeCount
        isWritingToPasteboard = false
        let language = settingsProvider().language
        notify(title: L10n.text(.copied, language), body: L10n.text(.copiedBody, language))
    }

    private func poll() {
        guard pasteboard.changeCount != lastChangeCount else {
            return
        }

        lastChangeCount = pasteboard.changeCount
        guard !isWritingToPasteboard, !settingsProvider().isRecordingPaused else {
            return
        }

        if let text = pasteboard.string(forType: .string) {
            record(text: text)
            return
        }

        if let data = pasteboard.data(forType: .png) ?? pasteboard.data(forType: NSPasteboard.PasteboardType("public.jpeg")) ?? pasteboard.data(forType: NSPasteboard.PasteboardType("public.webp")) ?? pasteboard.data(forType: .tiff) {
            record(imageData: data)
        }
    }

    private func record(text: String) {
        switch HistoryRules.decisionForText(text) {
        case .record:
            let now = Date()
            let app = NSWorkspace.shared.frontmostApplication
            let item = ClipboardItem(
                contentHash: ContentHashing.hash(text: text),
                kind: .text,
                text: text,
                sourceAppName: app?.localizedName,
                sourceBundleIdentifier: app?.bundleIdentifier,
                createdAt: now,
                updatedAt: now
            )
            do {
                try store.upsert(item)
                try store.cleanup(settings: settingsProvider())
                onChange()
            } catch {
                let language = settingsProvider().language
                notify(title: L10n.text(.notRecorded, language), body: L10n.text(.historyCouldNotBeSaved, language))
            }
        case .ignoreOversized:
            let language = settingsProvider().language
            notify(title: L10n.text(.notRecorded, language), body: L10n.text(.oversizedText, language))
        case .ignoreEmpty:
            break
        }
    }

    private func record(imageData data: Data) {
        switch HistoryRules.decisionForImageData(data) {
        case .record:
            guard let pngData = pngData(from: data) else {
                return
            }

            do {
                try FileManager.default.createDirectory(at: imageDirectory, withIntermediateDirectories: true)
                let now = Date()
                let hash = ContentHashing.hash(data: pngData)
                let fileURL = imageDirectory.appendingPathComponent("\(hash).png")
                try pngData.write(to: fileURL, options: [.atomic])

                let app = NSWorkspace.shared.frontmostApplication
                let item = ClipboardItem(
                    contentHash: hash,
                    kind: .image,
                    imagePath: fileURL.path,
                    thumbnailPath: fileURL.path,
                    sourceAppName: app?.localizedName,
                    sourceBundleIdentifier: app?.bundleIdentifier,
                    createdAt: now,
                    updatedAt: now
                )
                try store.upsert(item)
                try store.cleanup(settings: settingsProvider())
                onChange()
            } catch {
                let language = settingsProvider().language
                notify(title: L10n.text(.notRecorded, language), body: L10n.text(.imageCouldNotBeSaved, language))
            }
        case .ignoreOversized:
            let language = settingsProvider().language
            notify(title: L10n.text(.notRecorded, language), body: L10n.text(.oversizedImage, language))
        case .ignoreEmpty:
            break
        }
    }

    private func pngData(from data: Data) -> Data? {
        guard let image = NSImage(data: data), let tiff = image.tiffRepresentation else {
            return nil
        }
        guard let bitmap = NSBitmapImageRep(data: tiff) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
    }

    private func notify(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        notificationCenter?.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }
}
