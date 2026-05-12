import CopyToolsCore
import Foundation

@discardableResult
@MainActor
func expect(_ condition: @autoclosure () -> Bool, _ message: String) -> Bool {
    if condition() {
        return true
    }
    failures.append(message)
    return false
}

var failures: [String] = []

@MainActor
func runHistoryRuleChecks() {
    expect(HistoryRules.decisionForText("   \n\t") == .ignoreEmpty, "empty text should be ignored")

    let oversizedText = String(repeating: "a", count: HistoryRules.maxTextBytes + 1)
    expect(HistoryRules.decisionForText(oversizedText) == .ignoreOversized, "oversized text should be ignored")
    expect(HistoryRules.decisionForText("hello") == .record, "normal text should be recorded")

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
    expect(retained.map(\.contentHash) == ["recent"], "cleanup should remove expired normal items")

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
    expect(favoriteKept.map(\.contentHash) == ["favorite"], "favorites should be kept by default")

    let favoriteCleaned = HistoryRules.cleanedItems(
        from: [favorite],
        settings: AppSettings(retentionPeriod: .hours24, itemLimit: 100, cleanupFavorites: true),
        now: now
    )
    expect(favoriteCleaned.isEmpty, "favorites should be cleaned when setting is enabled")

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
    expect(limited.count == 100, "cleanup should keep items within configured limit")
    expect(limited.first?.contentHash == "104", "cleanup should keep newest item first")
    expect(limited.last?.contentHash == "5", "cleanup should remove oldest items first")
}

@MainActor
func runHistoryStoreChecks() throws {
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
    expect(items.count == 1, "duplicate content should not create a second row")
    expect(items.first?.id == id, "duplicate content should keep existing id")
    expect(items.first?.sourceAppName == "B", "duplicate content should update source app")
    expect(items.first?.updatedAt == Date(timeIntervalSince1970: 2), "duplicate content should update timestamp")

    let favoriteStore = try makeStore()
    let older = ClipboardItem(contentHash: "older", kind: .text, text: "older")
    let newer = ClipboardItem(contentHash: "newer", kind: .text, text: "newer")

    try favoriteStore.upsert(older)
    try favoriteStore.upsert(newer)
    try favoriteStore.setFavorite(true, for: older.id, at: Date(timeIntervalSince1970: 1))
    try favoriteStore.setFavorite(true, for: newer.id, at: Date(timeIntervalSince1970: 2))

    let favorites = try favoriteStore.items(favoritesOnly: true)
    expect(favorites.map(\.contentHash) == ["newer", "older"], "favorites should sort by favorite time descending")

    let sourceStore = try makeStore()
    try sourceStore.upsert(ClipboardItem(
        contentHash: "source-1",
        kind: .text,
        text: "one",
        sourceAppName: "Notes",
        sourceBundleIdentifier: "com.apple.Notes"
    ))
    try sourceStore.upsert(ClipboardItem(
        contentHash: "source-2",
        kind: .text,
        text: "two",
        sourceAppName: "Notes",
        sourceBundleIdentifier: "com.apple.Notes"
    ))
    let sources = try sourceStore.sourceApps()
    expect(sources.first?.bundleIdentifier == "com.apple.Notes", "source apps should include bundle id")
    expect(sources.first?.itemCount == 2, "source apps should include item count")

    let titleStore = try makeStore()
    let titled = ClipboardItem(contentHash: "titled", kind: .text, text: "invoice body")
    try titleStore.upsert(titled)
    try titleStore.setTitle("finance note", for: titled.id)

    let titleResults = try titleStore.items(search: "finance", searchMode: .title)
    expect(titleResults.map(\.contentHash) == ["titled"], "title search should match title")

    let contentResults = try titleStore.items(search: "invoice", searchMode: .content)
    expect(contentResults.map(\.contentHash) == ["titled"], "content search should match content")

    let mixedResults = try titleStore.items(search: "finance", searchMode: .mixed)
    expect(mixedResults.map(\.contentHash) == ["titled"], "mixed search should match title")

    let contentOnlyMiss = try titleStore.items(search: "finance", searchMode: .content)
    expect(contentOnlyMiss.isEmpty, "content-only search should not match title")

    let cleanupStore = try makeStore()
    try cleanupStore.upsert(ClipboardItem(
        contentHash: "cleanup",
        kind: .text,
        text: "cleanup",
        updatedAt: Date()
    ))
    try cleanupStore.cleanup(settings: AppSettings())
    let cleanupItems = try cleanupStore.items(limit: Int.max)
    expect(cleanupItems.count == 1, "cleanup should support unbounded internal reads")
}

func makeStore() throws -> HistoryStore {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("CopyToolsChecks-\(UUID().uuidString)", isDirectory: true)
    return try HistoryStore(databaseURL: directory.appendingPathComponent("history.sqlite"))
}

runHistoryRuleChecks()

do {
    try runHistoryStoreChecks()
} catch {
    failures.append("store checks threw error: \(error)")
}

if failures.isEmpty {
    print("CopyToolsChecks passed")
} else {
    for failure in failures {
        print("FAIL: \(failure)")
    }
    exit(1)
}
