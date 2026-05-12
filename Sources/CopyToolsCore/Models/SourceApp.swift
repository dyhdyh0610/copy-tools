import Foundation

public struct SourceApp: Identifiable, Equatable, Sendable {
    public var id: String { bundleIdentifier }
    public var bundleIdentifier: String
    public var name: String
    public var itemCount: Int

    public init(bundleIdentifier: String, name: String, itemCount: Int) {
        self.bundleIdentifier = bundleIdentifier
        self.name = name
        self.itemCount = itemCount
    }
}
