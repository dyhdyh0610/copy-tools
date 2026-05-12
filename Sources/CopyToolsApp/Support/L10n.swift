import CopyToolsCore
import Foundation

enum L10n {
    static func text(_ key: Key, _ language: AppLanguage) -> String {
        switch language {
        case .zhHans:
            return zh[key] ?? en[key] ?? key.rawValue
        case .en:
            return en[key] ?? key.rawValue
        }
    }

    static func languageName(_ language: AppLanguage) -> String {
        switch language {
        case .zhHans:
            return "中文"
        case .en:
            return "English"
        }
    }

    static func retentionName(_ period: RetentionPeriod, _ language: AppLanguage) -> String {
        switch (period, language) {
        case (.hours24, .zhHans):
            return "24 小时"
        case (.days7, .zhHans):
            return "7 天"
        case (.days30, .zhHans):
            return "30 天"
        case (.hours24, .en):
            return "24h"
        case (.days7, .en):
            return "7 days"
        case (.days30, .en):
            return "30 days"
        }
    }

    static func searchModeName(_ mode: SearchMode, _ language: AppLanguage) -> String {
        switch mode {
        case .content:
            return text(.searchContent, language)
        case .title:
            return text(.searchTitle, language)
        case .mixed:
            return text(.searchMixed, language)
        }
    }

    enum Key: String, Hashable {
        case all
        case favorites
        case text
        case images
        case search
        case paused
        case sourceApp
        case allApps
        case searchMode
        case searchContent
        case searchTitle
        case searchMixed
        case recordTitle
        case titlePlaceholder
        case hidePanelOnDeactivate
        case openSettings
        case noHistory
        case undo
        case select
        case deleteSelected
        case deleteSelectedTitle
        case deleteItems
        case cancel
        case unknownApp
        case image
        case copy
        case imagePreviewUnavailable
        case language
        case retention
        case itemLimit
        case closePanelAfterCopy
        case launchAtLogin
        case launchAtLoginPackagedOnly
        case pauseRecording
        case cleanupFavorites
        case shortcut
        case history
        case clearNonFavorites
        case clearAll
        case clearNonFavoritesTitle
        case clearAllTitle
        case copied
        case copiedBody
        case notRecorded
        case oversizedText
        case oversizedImage
        case imageCouldNotBeSaved
        case historyCouldNotBeSaved
        case shortcutUnavailableTitle
        case shortcutUnavailableBody
        case deletedUndo
        case restored
        case selectedDeleted
        case loadFailed
        case favoriteFailed
        case deleteFailed
        case restoreFailed
        case clearFailed
        case launchAtLoginFailed
        case openHistory
        case resumeRecording
        case pauseRecordingMenu
        case settings
        case quit
        case starting
        case setupTitle
        case localSaveNote
        case startUsing
    }

    private static let zh: [Key: String] = [
        .all: "全部",
        .favorites: "收藏",
        .text: "文本",
        .images: "图像",
        .search: "搜索剪切板历史",
        .paused: "已暂停",
        .sourceApp: "来源应用",
        .allApps: "全部应用",
        .searchMode: "搜索范围",
        .searchContent: "只搜内容",
        .searchTitle: "只搜标题",
        .searchMixed: "标题和内容",
        .recordTitle: "标题",
        .titlePlaceholder: "给这条记录添加标题",
        .hidePanelOnDeactivate: "切到其他应用时关闭历史面板",
        .openSettings: "打开设置",
        .noHistory: "暂无剪切板历史",
        .undo: "撤销",
        .select: "选择",
        .deleteSelected: "删除所选",
        .deleteSelectedTitle: "删除选中的项目？",
        .deleteItems: "删除项目",
        .cancel: "取消",
        .unknownApp: "未知应用",
        .image: "图像",
        .copy: "复制",
        .imagePreviewUnavailable: "图像预览不可用",
        .language: "语言",
        .retention: "保留时间",
        .itemLimit: "数量上限",
        .closePanelAfterCopy: "复制后关闭面板",
        .launchAtLogin: "开机启动",
        .launchAtLoginPackagedOnly: "仅在已安装的 App 中可用。",
        .pauseRecording: "暂停记录",
        .cleanupFavorites: "收藏也参与自动清理",
        .shortcut: "快捷键",
        .history: "历史记录",
        .clearNonFavorites: "清空非收藏历史",
        .clearAll: "清空全部历史",
        .clearNonFavoritesTitle: "清空非收藏历史？",
        .clearAllTitle: "清空全部剪切板历史？",
        .copied: "已复制",
        .copiedBody: "剪切板项目已复制。",
        .notRecorded: "未记录",
        .oversizedText: "文本超过 1 MB。",
        .oversizedImage: "图像超过 20 MB。",
        .imageCouldNotBeSaved: "图像无法保存。",
        .historyCouldNotBeSaved: "历史记录无法保存。",
        .shortcutUnavailableTitle: "快捷键不可用",
        .shortcutUnavailableBody: "Option + C 无法注册，可能已被其他应用占用。仍可从菜单栏打开历史记录。",
        .deletedUndo: "已删除，可在 5 秒内撤销。",
        .restored: "已恢复",
        .selectedDeleted: "已删除所选项目。",
        .loadFailed: "无法加载历史记录。",
        .favoriteFailed: "无法更新收藏。",
        .deleteFailed: "无法删除项目。",
        .restoreFailed: "无法恢复项目。",
        .clearFailed: "无法清空历史。",
        .launchAtLoginFailed: "无法更新开机启动。",
        .openHistory: "打开历史记录",
        .resumeRecording: "恢复记录",
        .pauseRecordingMenu: "暂停记录",
        .settings: "设置",
        .quit: "退出 Copy Tools",
        .starting: "Copy Tools 正在启动...",
        .setupTitle: "设置 Copy Tools",
        .localSaveNote: "剪切板历史会保存在这台 Mac 本地。",
        .startUsing: "开始使用 Copy Tools"
    ]

    private static let en: [Key: String] = [
        .all: "All",
        .favorites: "Favorites",
        .text: "Text",
        .images: "Images",
        .search: "Search clipboard history",
        .paused: "Paused",
        .sourceApp: "Source App",
        .allApps: "All Apps",
        .searchMode: "Search Mode",
        .searchContent: "Content",
        .searchTitle: "Title",
        .searchMixed: "Title and Content",
        .recordTitle: "Title",
        .titlePlaceholder: "Add a title for this item",
        .hidePanelOnDeactivate: "Hide history panel when switching apps",
        .openSettings: "Open Settings",
        .noHistory: "No clipboard history",
        .undo: "Undo",
        .select: "Select",
        .deleteSelected: "Delete Selected",
        .deleteSelectedTitle: "Delete selected items?",
        .deleteItems: "Delete Items",
        .cancel: "Cancel",
        .unknownApp: "Unknown App",
        .image: "Image",
        .copy: "Copy",
        .imagePreviewUnavailable: "Image preview unavailable",
        .language: "Language",
        .retention: "Retention",
        .itemLimit: "Item limit",
        .closePanelAfterCopy: "Close panel after copy",
        .launchAtLogin: "Launch at login",
        .launchAtLoginPackagedOnly: "Available in the packaged app.",
        .pauseRecording: "Pause recording",
        .cleanupFavorites: "Favorites participate in cleanup",
        .shortcut: "Shortcut",
        .history: "History",
        .clearNonFavorites: "Clear Non-Favorite History",
        .clearAll: "Clear All History",
        .clearNonFavoritesTitle: "Clear non-favorite history?",
        .clearAllTitle: "Clear all clipboard history?",
        .copied: "Copied",
        .copiedBody: "Clipboard item copied.",
        .notRecorded: "Not Recorded",
        .oversizedText: "Text is larger than 1 MB.",
        .oversizedImage: "Image is larger than 20 MB.",
        .imageCouldNotBeSaved: "Image could not be saved.",
        .historyCouldNotBeSaved: "History could not be saved.",
        .shortcutUnavailableTitle: "Shortcut Unavailable",
        .shortcutUnavailableBody: "Option + C could not be registered. It may already be used by another app. You can still open history from the menu bar.",
        .deletedUndo: "Deleted. Undo available for 5 seconds.",
        .restored: "Restored",
        .selectedDeleted: "Selected items deleted.",
        .loadFailed: "Could not load history.",
        .favoriteFailed: "Could not update favorite.",
        .deleteFailed: "Could not delete item.",
        .restoreFailed: "Could not restore item.",
        .clearFailed: "Could not clear history.",
        .launchAtLoginFailed: "Could not update launch at login.",
        .openHistory: "Open History",
        .resumeRecording: "Resume Recording",
        .pauseRecordingMenu: "Pause Recording",
        .settings: "Settings",
        .quit: "Quit Copy Tools",
        .starting: "Copy Tools is starting...",
        .setupTitle: "Set Up Copy Tools",
        .localSaveNote: "Clipboard history is saved locally on this Mac.",
        .startUsing: "Start Using Copy Tools"
    ]
}
