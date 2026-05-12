import Foundation

enum AppPaths {
    static var applicationSupportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
        return base.appendingPathComponent("CopyTools", isDirectory: true)
    }

    static var databaseURL: URL {
        applicationSupportDirectory.appendingPathComponent("history.sqlite")
    }

    static var settingsURL: URL {
        applicationSupportDirectory.appendingPathComponent("settings.json")
    }

    static var imageDirectory: URL {
        applicationSupportDirectory.appendingPathComponent("Images", isDirectory: true)
    }
}
