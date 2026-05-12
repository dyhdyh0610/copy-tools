import Foundation

public enum ClipboardItemKind: String, Codable, CaseIterable, Sendable {
    case text
    case image
}

public struct ClipboardItem: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var contentHash: String
    public var title: String?
    public var kind: ClipboardItemKind
    public var text: String?
    public var imagePath: String?
    public var thumbnailPath: String?
    public var sourceAppName: String?
    public var sourceBundleIdentifier: String?
    public var createdAt: Date
    public var updatedAt: Date
    public var isFavorite: Bool
    public var favoritedAt: Date?

    public init(
        id: UUID = UUID(),
        contentHash: String,
        title: String? = nil,
        kind: ClipboardItemKind,
        text: String? = nil,
        imagePath: String? = nil,
        thumbnailPath: String? = nil,
        sourceAppName: String? = nil,
        sourceBundleIdentifier: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isFavorite: Bool = false,
        favoritedAt: Date? = nil
    ) {
        self.id = id
        self.contentHash = contentHash
        self.title = title
        self.kind = kind
        self.text = text
        self.imagePath = imagePath
        self.thumbnailPath = thumbnailPath
        self.sourceAppName = sourceAppName
        self.sourceBundleIdentifier = sourceBundleIdentifier
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isFavorite = isFavorite
        self.favoritedAt = favoritedAt
    }
}
