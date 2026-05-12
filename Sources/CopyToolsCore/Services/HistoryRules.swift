import Foundation

public enum ClipboardRecordDecision: Equatable {
    case record
    case ignoreEmpty
    case ignoreOversized
}

public enum HistoryRules {
    public static let maxTextBytes = 1_048_576
    public static let maxImageBytes = 20_971_520

    public static func decisionForText(_ text: String) -> ClipboardRecordDecision {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .ignoreEmpty
        }

        guard Data(text.utf8).count <= maxTextBytes else {
            return .ignoreOversized
        }

        return .record
    }

    public static func decisionForImageData(_ data: Data) -> ClipboardRecordDecision {
        guard !data.isEmpty else {
            return .ignoreEmpty
        }

        guard data.count <= maxImageBytes else {
            return .ignoreOversized
        }

        return .record
    }

    public static func cleanedItems(
        from items: [ClipboardItem],
        settings: AppSettings,
        now: Date
    ) -> [ClipboardItem] {
        let cutoff = now.addingTimeInterval(-settings.retentionPeriod.seconds)
        let timeFiltered = items.filter { item in
            if item.isFavorite && !settings.cleanupFavorites {
                return true
            }

            return item.updatedAt >= cutoff
        }

        let exemptFavorites = timeFiltered.filter { $0.isFavorite && !settings.cleanupFavorites }
        let limitedCandidates = timeFiltered.filter { !($0.isFavorite && !settings.cleanupFavorites) }
            .sorted { $0.updatedAt > $1.updatedAt }

        let limited = Array(limitedCandidates.prefix(settings.itemLimit))
        return (exemptFavorites + limited).sorted { lhs, rhs in
            lhs.updatedAt > rhs.updatedAt
        }
    }
}
