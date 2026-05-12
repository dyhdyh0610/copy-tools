import Foundation
import ServiceManagement

enum LaunchAtLoginManager {
    static var isAvailable: Bool {
        AppRuntime.isAppBundle
    }

    static var isEnabled: Bool {
        guard isAvailable else {
            return false
        }

        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }

        return false
    }

    static func setEnabled(_ enabled: Bool) throws {
        guard isAvailable else {
            return
        }

        if #available(macOS 13.0, *) {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }
        }
    }
}
