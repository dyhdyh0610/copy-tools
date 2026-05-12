import Foundation

public enum RetentionPeriod: String, Codable, CaseIterable, Sendable {
    case hours24
    case days7
    case days30

    public var seconds: TimeInterval {
        switch self {
        case .hours24:
            return 24 * 60 * 60
        case .days7:
            return 7 * 24 * 60 * 60
        case .days30:
            return 30 * 24 * 60 * 60
        }
    }

    public var displayName: String {
        switch self {
        case .hours24:
            return "24h"
        case .days7:
            return "7 days"
        case .days30:
            return "30 days"
        }
    }
}

public enum AppLanguage: String, Codable, CaseIterable, Sendable {
    case zhHans
    case en
}

public enum SearchMode: String, Codable, CaseIterable, Sendable {
    case content
    case title
    case mixed
}

public struct AppSettings: Codable, Equatable, Sendable {
    public var retentionPeriod: RetentionPeriod
    public var itemLimit: Int
    public var closePanelAfterCopy: Bool
    public var launchAtLogin: Bool
    public var isRecordingPaused: Bool
    public var cleanupFavorites: Bool
    public var shortcutDisplayName: String
    public var hasCompletedFirstLaunchGuide: Bool
    public var language: AppLanguage
    public var searchMode: SearchMode
    public var hidesHistoryPanelOnDeactivate: Bool
    public var hasPromptedForAccessibilityPermission: Bool

    enum CodingKeys: String, CodingKey {
        case retentionPeriod
        case itemLimit
        case closePanelAfterCopy
        case launchAtLogin
        case isRecordingPaused
        case cleanupFavorites
        case shortcutDisplayName
        case hasCompletedFirstLaunchGuide
        case language
        case searchMode
        case hidesHistoryPanelOnDeactivate
        case hasPromptedForAccessibilityPermission
    }

    public init(
        retentionPeriod: RetentionPeriod = .days7,
        itemLimit: Int = 500,
        closePanelAfterCopy: Bool = false,
        launchAtLogin: Bool = false,
        isRecordingPaused: Bool = false,
        cleanupFavorites: Bool = false,
        shortcutDisplayName: String = "Option + C",
        hasCompletedFirstLaunchGuide: Bool = false,
        language: AppLanguage = .zhHans,
        searchMode: SearchMode = .mixed,
        hidesHistoryPanelOnDeactivate: Bool = true,
        hasPromptedForAccessibilityPermission: Bool = false
    ) {
        self.retentionPeriod = retentionPeriod
        self.itemLimit = max(100, min(2000, itemLimit))
        self.closePanelAfterCopy = closePanelAfterCopy
        self.launchAtLogin = launchAtLogin
        self.isRecordingPaused = isRecordingPaused
        self.cleanupFavorites = cleanupFavorites
        self.shortcutDisplayName = shortcutDisplayName
        self.hasCompletedFirstLaunchGuide = hasCompletedFirstLaunchGuide
        self.language = language
        self.searchMode = searchMode
        self.hidesHistoryPanelOnDeactivate = hidesHistoryPanelOnDeactivate
        self.hasPromptedForAccessibilityPermission = hasPromptedForAccessibilityPermission
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            retentionPeriod: try container.decodeIfPresent(RetentionPeriod.self, forKey: .retentionPeriod) ?? .days7,
            itemLimit: try container.decodeIfPresent(Int.self, forKey: .itemLimit) ?? 500,
            closePanelAfterCopy: try container.decodeIfPresent(Bool.self, forKey: .closePanelAfterCopy) ?? false,
            launchAtLogin: try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false,
            isRecordingPaused: try container.decodeIfPresent(Bool.self, forKey: .isRecordingPaused) ?? false,
            cleanupFavorites: try container.decodeIfPresent(Bool.self, forKey: .cleanupFavorites) ?? false,
            shortcutDisplayName: try container.decodeIfPresent(String.self, forKey: .shortcutDisplayName) ?? "Option + C",
            hasCompletedFirstLaunchGuide: try container.decodeIfPresent(Bool.self, forKey: .hasCompletedFirstLaunchGuide) ?? false,
            language: try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .zhHans,
            searchMode: try container.decodeIfPresent(SearchMode.self, forKey: .searchMode) ?? .mixed,
            hidesHistoryPanelOnDeactivate: try container.decodeIfPresent(Bool.self, forKey: .hidesHistoryPanelOnDeactivate) ?? true,
            hasPromptedForAccessibilityPermission: try container.decodeIfPresent(Bool.self, forKey: .hasPromptedForAccessibilityPermission) ?? false
        )
    }
}
