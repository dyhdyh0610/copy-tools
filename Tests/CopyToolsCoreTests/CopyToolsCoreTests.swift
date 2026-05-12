import CopyToolsCore
import Foundation

#if canImport(Testing)
import Testing

@Suite("CopyToolsCore")
struct CopyToolsCoreTests {
    @Test
    func historyRulesIgnoreEmptyAndOversizedText() {
        #expect(HistoryRules.decisionForText("   \n\t") == .ignoreEmpty)

        let oversizedText = String(repeating: "a", count: HistoryRules.maxTextBytes + 1)
        #expect(HistoryRules.decisionForText(oversizedText) == .ignoreOversized)
        #expect(HistoryRules.decisionForText("hello") == .record)
    }

    @Test
    func cleanupRemovesExpiredNormalItems() {
        let now = Date(timeIntervalSince1970: 10_000)
        let expired = ClipboardItem(
            contentHash: "old",
            kind: .text,
            text: "old",
            updatedAt: now.addingTimeInterval(-RetentionPeriod.hours24.seconds - 1)
        )
        let recent = ClipboardItem(
            contentHash: "recent",
            kind: .text,
            text: "recent",
            updatedAt: now
        )

        let retained = HistoryRules.cleanedItems(
            from: [expired, recent],
            settings: AppSettings(retentionPeriod: .hours24, itemLimit: 100),
            now: now
        )

        #expect(retained.map(\.contentHash) == ["recent"])
    }

    @Test
    func cleanupRespectsFavoriteSetting() {
        let now = Date(timeIntervalSince1970: 10_000)
        let favorite = ClipboardItem(
            contentHash: "favorite",
            kind: .text,
            text: "favorite",
            updatedAt: now.addingTimeInterval(-RetentionPeriod.hours24.seconds - 1),
            isFavorite: true,
            favoritedAt: now
        )

        let favoriteKept = HistoryRules.cleanedItems(
            from: [favorite],
            settings: AppSettings(retentionPeriod: .hours24, itemLimit: 100, cleanupFavorites: false),
            now: now
        )
        #expect(favoriteKept.map(\.contentHash) == ["favorite"])

        let favoriteCleaned = HistoryRules.cleanedItems(
            from: [favorite],
            settings: AppSettings(retentionPeriod: .hours24, itemLimit: 100, cleanupFavorites: true),
            now: now
        )
        #expect(favoriteCleaned.isEmpty)
    }

    @Test
    func cleanupKeepsNewestItemsWithinLimit() {
        let now = Date(timeIntervalSince1970: 10_000)
        let limitedItems = (0..<105).map { index in
            ClipboardItem(
                contentHash: "\(index)",
                kind: .text,
                text: "\(index)",
                updatedAt: now.addingTimeInterval(TimeInterval(index))
            )
        }

        let limited = HistoryRules.cleanedItems(
            from: limitedItems,
            settings: AppSettings(retentionPeriod: .days7, itemLimit: 100),
            now: now
        )

        #expect(limited.count == 100)
        #expect(limited.first?.contentHash == "104")
        #expect(limited.last?.contentHash == "5")
    }

    @Test
    func duplicateUpsertUpdatesExistingRow() throws {
        let store = try makeStore()
        let id = UUID()
        let first = ClipboardItem(
            id: id,
            contentHash: "same",
            kind: .text,
            text: "hello",
            sourceAppName: "A",
            updatedAt: Date(timeIntervalSince1970: 1)
        )
        let second = ClipboardItem(
            contentHash: "same",
            kind: .text,
            text: "hello",
            sourceAppName: "B",
            updatedAt: Date(timeIntervalSince1970: 2)
        )

        try store.upsert(first)
        try store.upsert(second)

        let items = try store.items()
        #expect(items.count == 1)
        #expect(items.first?.id == id)
        #expect(items.first?.sourceAppName == "B")
        #expect(items.first?.updatedAt == Date(timeIntervalSince1970: 2))
    }

    @Test
    func favoritesSortByFavoriteTimeDescending() throws {
        let store = try makeStore()
        let older = ClipboardItem(contentHash: "older", kind: .text, text: "older")
        let newer = ClipboardItem(contentHash: "newer", kind: .text, text: "newer")

        try store.upsert(older)
        try store.upsert(newer)
        try store.setFavorite(true, for: older.id, at: Date(timeIntervalSince1970: 1))
        try store.setFavorite(true, for: newer.id, at: Date(timeIntervalSince1970: 2))

        let favorites = try store.items(favoritesOnly: true)
        #expect(favorites.map(\.contentHash) == ["newer", "older"])
    }

    @Test
    func sourceAppsIncludeBundleIDAndCount() throws {
        let store = try makeStore()
        try store.upsert(ClipboardItem(
            contentHash: "source-1",
            kind: .text,
            text: "one",
            sourceAppName: "Notes",
            sourceBundleIdentifier: "com.apple.Notes"
        ))
        try store.upsert(ClipboardItem(
            contentHash: "source-2",
            kind: .text,
            text: "two",
            sourceAppName: "Notes",
            sourceBundleIdentifier: "com.apple.Notes"
        ))

        let sources = try store.sourceApps()
        #expect(sources.first?.bundleIdentifier == "com.apple.Notes")
        #expect(sources.first?.itemCount == 2)
    }

    @Test
    func searchModesRespectTitleAndContent() throws {
        let store = try makeStore()
        let titled = ClipboardItem(contentHash: "titled", kind: .text, text: "invoice body")
        try store.upsert(titled)
        try store.setTitle("finance note", for: titled.id)

        let titleResults = try store.items(search: "finance", searchMode: .title)
        #expect(titleResults.map(\.contentHash) == ["titled"])

        let contentResults = try store.items(search: "invoice", searchMode: .content)
        #expect(contentResults.map(\.contentHash) == ["titled"])

        let mixedResults = try store.items(search: "finance", searchMode: .mixed)
        #expect(mixedResults.map(\.contentHash) == ["titled"])

        let contentOnlyMiss = try store.items(search: "finance", searchMode: .content)
        #expect(contentOnlyMiss.isEmpty)
    }

    @Test
    func cleanupSupportsUnboundedInternalReads() throws {
        let store = try makeStore()
        try store.upsert(ClipboardItem(
            contentHash: "cleanup",
            kind: .text,
            text: "cleanup",
            updatedAt: Date()
        ))
        try store.cleanup(settings: AppSettings())

        let cleanupItems = try store.items(limit: Int.max)
        #expect(cleanupItems.count == 1)
    }

    private func makeStore() throws -> HistoryStore {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CopyToolsCoreTests-\(UUID().uuidString)", isDirectory: true)
        return try HistoryStore(databaseURL: directory.appendingPathComponent("history.sqlite"))
    }
}
#else
struct CopyToolsCoreBuildProbe {
    let defaultSettings = AppSettings()
}
#endif
