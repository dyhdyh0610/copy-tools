import Foundation

public final class SettingsStore {
    private let url: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(url: URL) {
        self.url = url
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    public func load() -> AppSettings {
        guard let data = try? Data(contentsOf: url) else {
            return AppSettings()
        }

        guard var settings = try? decoder.decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        settings.itemLimit = max(100, min(2000, settings.itemLimit))
        return settings
    }

    public func save(_ settings: AppSettings) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try encoder.encode(settings)
        try data.write(to: url, options: [.atomic])
    }
}
