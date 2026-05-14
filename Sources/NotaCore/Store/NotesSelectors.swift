import Foundation

public enum VerticalDirection: String, Codable, Equatable, Sendable {
    case up
    case down
}

public enum HorizontalDirection: String, Codable, Equatable, Sendable {
    case left
    case right
}

public enum NotesSelectors {
    public static func activeTab(in tabs: [Tab], activeTabId: String) -> Tab? {
        tabs.first { $0.id == activeTabId }
    }

    public static func cursorForTab(_ tab: Tab?) -> Int {
        guard let tab, tab.items.isEmpty == false else {
            return -1
        }

        return 0
    }

    public static func clampCursor(_ index: Int, in tab: Tab?) -> Int {
        guard let tab, tab.items.isEmpty == false else {
            return -1
        }

        return min(max(index, 0), tab.items.count - 1)
    }
}
