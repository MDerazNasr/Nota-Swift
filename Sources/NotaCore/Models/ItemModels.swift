import Foundation

public enum ItemState: String, Codable, Equatable, Sendable {
    case active
    case done
}

public struct ItemTag: Codable, Equatable, Identifiable, Sendable {
    public var name: String
    public var color: String
    public var normalizedName: String

    public var id: String {
        normalizedName
    }

    public init(name: String, color: String, normalizedName: String) {
        self.name = name
        self.color = color
        self.normalizedName = normalizedName
    }
}

public struct Item: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var richText: CodableRichText
    public var state: ItemState
    public var tags: [ItemTag]
    public var createdAt: TimeInterval

    public init(
        id: String,
        richText: CodableRichText,
        state: ItemState,
        tags: [ItemTag],
        createdAt: TimeInterval
    ) {
        self.id = id
        self.richText = richText
        self.state = state
        self.tags = tags
        self.createdAt = createdAt
    }
}

public struct Tab: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var title: String
    public var items: [Item]
    public var createdAt: TimeInterval

    public init(id: String, title: String, items: [Item], createdAt: TimeInterval) {
        self.id = id
        self.title = title
        self.items = items
        self.createdAt = createdAt
    }
}

public struct AppState: Codable, Equatable, Sendable {
    public var tabs: [Tab]
    public var activeTabId: String

    public init(tabs: [Tab], activeTabId: String) {
        self.tabs = tabs
        self.activeTabId = activeTabId
    }
}

public enum AppMode: String, Codable, Equatable, Sendable {
    case nav
    case edit
    case move
    case tabs
    case tabMove
}
