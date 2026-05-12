import CSQLite
import Foundation

public enum HistoryStoreError: Error {
    case openDatabaseFailed(String)
    case prepareFailed(String)
    case executeFailed(String)
}

public final class HistoryStore {
    private var database: OpaquePointer?
    private let databaseURL: URL

    public init(databaseURL: URL) throws {
        self.databaseURL = databaseURL
        try FileManager.default.createDirectory(
            at: databaseURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        guard sqlite3_open(databaseURL.path, &database) == SQLITE_OK else {
            throw HistoryStoreError.openDatabaseFailed(lastErrorMessage)
        }

        try migrate()
    }

    deinit {
        sqlite3_close(database)
    }

    public func upsert(_ item: ClipboardItem) throws {
        if let existing = try itemWithContentHash(item.contentHash) {
            try updateExisting(existing, with: item)
            return
        }

        let sql = """
        INSERT INTO clipboard_items (
            id, content_hash, title, kind, text, image_path, thumbnail_path,
            source_app_name, source_bundle_id, created_at, updated_at,
            is_favorite, favorited_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """

        try withStatement(sql) { statement in
            bindText(item.id.uuidString, to: statement, at: 1)
            bindText(item.contentHash, to: statement, at: 2)
            bindOptionalText(item.title, to: statement, at: 3)
            bindText(item.kind.rawValue, to: statement, at: 4)
            bindOptionalText(item.text, to: statement, at: 5)
            bindOptionalText(item.imagePath, to: statement, at: 6)
            bindOptionalText(item.thumbnailPath, to: statement, at: 7)
            bindOptionalText(item.sourceAppName, to: statement, at: 8)
            bindOptionalText(item.sourceBundleIdentifier, to: statement, at: 9)
            sqlite3_bind_double(statement, 10, item.createdAt.timeIntervalSince1970)
            sqlite3_bind_double(statement, 11, item.updatedAt.timeIntervalSince1970)
            sqlite3_bind_int(statement, 12, item.isFavorite ? 1 : 0)
            bindOptionalDate(item.favoritedAt, to: statement, at: 13)
            try stepDone(statement)
        }
    }

    public func items(
        search: String = "",
        searchMode: SearchMode = .mixed,
        kind: ClipboardItemKind? = nil,
        favoritesOnly: Bool = false,
        sourceBundleIdentifier: String? = nil,
        limit: Int = 500
    ) throws -> [ClipboardItem] {
        var clauses: [String] = []
        var bindings: [(OpaquePointer?, Int32) -> Void] = []

        if !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            switch searchMode {
            case .content:
                clauses.append("text LIKE ?")
                bindings.append { statement, index in
                    bindText("%\(search)%", to: statement, at: index)
                }
            case .title:
                clauses.append("title LIKE ?")
                bindings.append { statement, index in
                    bindText("%\(search)%", to: statement, at: index)
                }
            case .mixed:
                clauses.append("(text LIKE ? OR title LIKE ?)")
                bindings.append { statement, index in
                    bindText("%\(search)%", to: statement, at: index)
                }
                bindings.append { statement, index in
                    bindText("%\(search)%", to: statement, at: index)
                }
            }
        }

        if let kind {
            clauses.append("kind = ?")
            bindings.append { statement, index in
                bindText(kind.rawValue, to: statement, at: index)
            }
        }

        if favoritesOnly {
            clauses.append("is_favorite = 1")
        }

        if let sourceBundleIdentifier {
            clauses.append("source_bundle_id = ?")
            bindings.append { statement, index in
                bindText(sourceBundleIdentifier, to: statement, at: index)
            }
        }

        let whereClause = clauses.isEmpty ? "" : "WHERE " + clauses.joined(separator: " AND ")
        let orderClause = favoritesOnly
            ? "ORDER BY favorited_at DESC, updated_at DESC"
            : "ORDER BY updated_at DESC"
        let sql = """
        SELECT id, content_hash, title, kind, text, image_path, thumbnail_path,
               source_app_name, source_bundle_id, created_at, updated_at,
               is_favorite, favorited_at
        FROM clipboard_items
        \(whereClause)
        \(orderClause)
        LIMIT ?;
        """

        return try withStatement(sql) { statement in
            for (offset, bind) in bindings.enumerated() {
                bind(statement, Int32(offset + 1))
            }
            sqlite3_bind_int64(statement, Int32(bindings.count + 1), sqlite3_int64(limit))

            var result: [ClipboardItem] = []
            while sqlite3_step(statement) == SQLITE_ROW {
                result.append(readItem(from: statement))
            }
            return result
        }
    }

    public func sourceApps() throws -> [SourceApp] {
        let sql = """
        SELECT source_bundle_id, COALESCE(source_app_name, source_bundle_id), COUNT(*)
        FROM clipboard_items
        WHERE source_bundle_id IS NOT NULL AND source_bundle_id != ''
        GROUP BY source_bundle_id
        ORDER BY COUNT(*) DESC, source_app_name ASC;
        """

        return try withStatement(sql) { statement in
            var result: [SourceApp] = []
            while sqlite3_step(statement) == SQLITE_ROW {
                guard let bundleIdentifier = optionalText(statement, 0) else {
                    continue
                }
                result.append(SourceApp(
                    bundleIdentifier: bundleIdentifier,
                    name: optionalText(statement, 1) ?? bundleIdentifier,
                    itemCount: Int(sqlite3_column_int(statement, 2))
                ))
            }
            return result
        }
    }

    public func setFavorite(_ isFavorite: Bool, for id: UUID, at date: Date = Date()) throws {
        let sql = "UPDATE clipboard_items SET is_favorite = ?, favorited_at = ? WHERE id = ?;"
        try withStatement(sql) { statement in
            sqlite3_bind_int(statement, 1, isFavorite ? 1 : 0)
            if isFavorite {
                sqlite3_bind_double(statement, 2, date.timeIntervalSince1970)
            } else {
                sqlite3_bind_null(statement, 2)
            }
            bindText(id.uuidString, to: statement, at: 3)
            try stepDone(statement)
        }
    }

    public func setTitle(_ title: String?, for id: UUID) throws {
        let trimmed = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let sql = "UPDATE clipboard_items SET title = ? WHERE id = ?;"
        try withStatement(sql) { statement in
            bindOptionalText(trimmed?.isEmpty == true ? nil : trimmed, to: statement, at: 1)
            bindText(id.uuidString, to: statement, at: 2)
            try stepDone(statement)
        }
    }

    public func delete(id: UUID) throws {
        try execute("DELETE FROM clipboard_items WHERE id = '\(id.uuidString)';")
    }

    public func delete(ids: [UUID]) throws {
        for id in ids {
            try delete(id: id)
        }
    }

    public func clearNonFavorites() throws {
        try execute("DELETE FROM clipboard_items WHERE is_favorite = 0;")
    }

    public func clearAll() throws {
        try execute("DELETE FROM clipboard_items;")
    }

    public func cleanup(settings: AppSettings, now: Date = Date()) throws {
        let current = try items(limit: Int.max)
        let keptIDs = Set(HistoryRules.cleanedItems(from: current, settings: settings, now: now).map(\.id))
        let idsToDelete = current.map(\.id).filter { !keptIDs.contains($0) }
        try delete(ids: idsToDelete)
    }

    private func migrate() throws {
        try execute("""
        CREATE TABLE IF NOT EXISTS clipboard_items (
            id TEXT PRIMARY KEY,
            content_hash TEXT NOT NULL UNIQUE,
            title TEXT,
            kind TEXT NOT NULL,
            text TEXT,
            image_path TEXT,
            thumbnail_path TEXT,
            source_app_name TEXT,
            source_bundle_id TEXT,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL,
            is_favorite INTEGER NOT NULL DEFAULT 0,
            favorited_at REAL
        );
        """)
        try addColumnIfNeeded(table: "clipboard_items", column: "title", definition: "TEXT")
        try execute("CREATE INDEX IF NOT EXISTS idx_clipboard_items_updated_at ON clipboard_items(updated_at);")
        try execute("CREATE INDEX IF NOT EXISTS idx_clipboard_items_kind ON clipboard_items(kind);")
        try execute("CREATE INDEX IF NOT EXISTS idx_clipboard_items_favorite ON clipboard_items(is_favorite, favorited_at);")
    }

    private func itemWithContentHash(_ hash: String) throws -> ClipboardItem? {
        let sql = """
        SELECT id, content_hash, title, kind, text, image_path, thumbnail_path,
               source_app_name, source_bundle_id, created_at, updated_at,
               is_favorite, favorited_at
        FROM clipboard_items
        WHERE content_hash = ?
        LIMIT 1;
        """

        return try withStatement(sql) { statement in
            bindText(hash, to: statement, at: 1)
            guard sqlite3_step(statement) == SQLITE_ROW else {
                return nil
            }
            return readItem(from: statement)
        }
    }

    private func updateExisting(_ existing: ClipboardItem, with incoming: ClipboardItem) throws {
        let sql = """
        UPDATE clipboard_items
        SET updated_at = ?, source_app_name = ?, source_bundle_id = ?,
            image_path = COALESCE(?, image_path),
            thumbnail_path = COALESCE(?, thumbnail_path)
        WHERE id = ?;
        """
        try withStatement(sql) { statement in
            sqlite3_bind_double(statement, 1, incoming.updatedAt.timeIntervalSince1970)
            bindOptionalText(incoming.sourceAppName, to: statement, at: 2)
            bindOptionalText(incoming.sourceBundleIdentifier, to: statement, at: 3)
            bindOptionalText(incoming.imagePath, to: statement, at: 4)
            bindOptionalText(incoming.thumbnailPath, to: statement, at: 5)
            bindText(existing.id.uuidString, to: statement, at: 6)
            try stepDone(statement)
        }
    }

    private func execute(_ sql: String) throws {
        var errorMessage: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(database, sql, nil, nil, &errorMessage) == SQLITE_OK else {
            let message = errorMessage.map { String(cString: $0) } ?? lastErrorMessage
            sqlite3_free(errorMessage)
            throw HistoryStoreError.executeFailed(message)
        }
    }

    private func addColumnIfNeeded(table: String, column: String, definition: String) throws {
        let escapedTable = table.replacingOccurrences(of: "'", with: "''")
        let existingColumns = try withStatement("PRAGMA table_info('\(escapedTable)');") { statement in
            var columns = Set<String>()
            while sqlite3_step(statement) == SQLITE_ROW {
                if let name = optionalText(statement, 1) {
                    columns.insert(name)
                }
            }
            return columns
        }

        guard !existingColumns.contains(column) else {
            return
        }

        try execute("ALTER TABLE \(table) ADD COLUMN \(column) \(definition);")
    }

    private func withStatement<T>(_ sql: String, body: (OpaquePointer?) throws -> T) throws -> T {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw HistoryStoreError.prepareFailed(lastErrorMessage)
        }
        defer { sqlite3_finalize(statement) }
        return try body(statement)
    }

    private func stepDone(_ statement: OpaquePointer?) throws {
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw HistoryStoreError.executeFailed(lastErrorMessage)
        }
    }

    private var lastErrorMessage: String {
        database.map { String(cString: sqlite3_errmsg($0)) } ?? "Unknown SQLite error"
    }
}

private func bindText(_ value: String, to statement: OpaquePointer?, at index: Int32) {
    sqlite3_bind_text(statement, index, value, -1, SQLITE_TRANSIENT)
}

private func bindOptionalText(_ value: String?, to statement: OpaquePointer?, at index: Int32) {
    guard let value else {
        sqlite3_bind_null(statement, index)
        return
    }
    bindText(value, to: statement, at: index)
}

private func bindOptionalDate(_ value: Date?, to statement: OpaquePointer?, at index: Int32) {
    guard let value else {
        sqlite3_bind_null(statement, index)
        return
    }
    sqlite3_bind_double(statement, index, value.timeIntervalSince1970)
}

private func optionalText(_ statement: OpaquePointer?, _ index: Int32) -> String? {
    guard let pointer = sqlite3_column_text(statement, index) else {
        return nil
    }
    return String(cString: pointer)
}

private func readItem(from statement: OpaquePointer?) -> ClipboardItem {
    let idText = optionalText(statement, 0) ?? UUID().uuidString
    let kindText = optionalText(statement, 3) ?? ClipboardItemKind.text.rawValue
    let favoritedValue = sqlite3_column_type(statement, 12) == SQLITE_NULL
        ? nil
        : Date(timeIntervalSince1970: sqlite3_column_double(statement, 12))

    return ClipboardItem(
        id: UUID(uuidString: idText) ?? UUID(),
        contentHash: optionalText(statement, 1) ?? "",
        title: optionalText(statement, 2),
        kind: ClipboardItemKind(rawValue: kindText) ?? .text,
        text: optionalText(statement, 4),
        imagePath: optionalText(statement, 5),
        thumbnailPath: optionalText(statement, 6),
        sourceAppName: optionalText(statement, 7),
        sourceBundleIdentifier: optionalText(statement, 8),
        createdAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 9)),
        updatedAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 10)),
        isFavorite: sqlite3_column_int(statement, 11) == 1,
        favoritedAt: favoritedValue
    )
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
