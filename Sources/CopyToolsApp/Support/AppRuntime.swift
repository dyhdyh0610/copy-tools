import Foundation

enum AppRuntime {
    static var isAppBundle: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }
}
