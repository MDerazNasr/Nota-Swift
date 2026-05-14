import Foundation

public enum NotesItems {
    public static func insert(_ item: Item, into items: [Item], at index: Int) -> [Item] {
        var items = items
        let safeIndex = min(max(index, 0), items.count)
        items.insert(item, at: safeIndex)
        return items
    }

    public static func removeItemState(
        tabs: [Tab],
        tabId: String,
        itemId: String,
        cursorIndex: Int,
        selectedItemIds: [String]
    ) -> (tabs: [Tab], cursorIndex: Int, selectedItemIds: [String])? {
        guard let tab = tabs.first(where: { $0.id == tabId }),
              let removedIndex = tab.items.firstIndex(where: { $0.id == itemId }) else {
            return nil
        }

        let nextTabs = tabs.map { current in
            guard current.id == tabId else {
                return current
            }

            var items = current.items
            items.remove(at: removedIndex)
            return Tab(id: current.id, title: current.title, items: items, createdAt: current.createdAt)
        }
        let nextTab = nextTabs.first(where: { $0.id == tabId })
        let nextCursor = NotesSelectors.clampCursor(cursorIndex == removedIndex ? removedIndex : cursorIndex, in: nextTab)
        let nextSelected = selectedItemIds.filter { $0 != itemId }
        return (nextTabs, nextCursor, nextSelected)
    }

    public static func toggleDoneState(
        tabs: [Tab],
        tabId: String,
        itemId: String
    ) -> (tabs: [Tab], cursorIndex: Int)? {
        guard let tab = tabs.first(where: { $0.id == tabId }),
              let itemIndex = tab.items.firstIndex(where: { $0.id == itemId }) else {
            return nil
        }

        var items = tab.items
        var item = items.remove(at: itemIndex)
        item.state = item.state == .active ? .done : .active
        items.append(item)
        let nextTabs = tabs.map { current in
            current.id == tabId ? Tab(id: current.id, title: current.title, items: items, createdAt: current.createdAt) : current
        }
        let nextCursor = items.firstIndex(where: { $0.id == itemId }) ?? NotesSelectors.cursorForTab(tab)
        return (nextTabs, nextCursor)
    }

    public static func sortItemsByTagState(
        tabs: [Tab],
        tabId: String,
        cursorIndex: Int
    ) -> (tabs: [Tab], cursorIndex: Int)? {
        guard let tab = tabs.first(where: { $0.id == tabId }),
              tab.items.count > 1,
              tab.items.contains(where: { $0.tags.isEmpty == false }) else {
            return nil
        }

        let focusedId = tab.items.indices.contains(cursorIndex) ? tab.items[cursorIndex].id : nil
        let items = sortItemsByTag(tab.items)
        let nextCursor = focusedId.flatMap { focusedId in items.firstIndex(where: { $0.id == focusedId }) } ?? NotesSelectors.clampCursor(cursorIndex, in: Tab(id: tab.id, title: tab.title, items: items, createdAt: tab.createdAt))
        let nextTabs = tabs.map { current in
            current.id == tabId ? Tab(id: current.id, title: current.title, items: items, createdAt: current.createdAt) : current
        }
        return (nextTabs, nextCursor)
    }

    public static func restoreItemsByOrderState(
        tabs: [Tab],
        tabId: String,
        orderedItemIds: [String],
        cursorIndex: Int
    ) -> (tabs: [Tab], cursorIndex: Int)? {
        guard let tab = tabs.first(where: { $0.id == tabId }) else {
            return nil
        }

        let focusedId = tab.items.indices.contains(cursorIndex) ? tab.items[cursorIndex].id : nil
        let itemsById = Dictionary(uniqueKeysWithValues: tab.items.map { ($0.id, $0) })
        let restored = orderedItemIds.compactMap { itemsById[$0] }
        let restoredIds = Set(restored.map(\.id))
        let newItems = tab.items.filter { restoredIds.contains($0.id) == false }
        let items = restored + newItems
        let nextCursor = focusedId.flatMap { focusedId in items.firstIndex(where: { $0.id == focusedId }) } ?? NotesSelectors.clampCursor(cursorIndex, in: Tab(id: tab.id, title: tab.title, items: items, createdAt: tab.createdAt))
        let nextTabs = tabs.map { current in
            current.id == tabId ? Tab(id: current.id, title: current.title, items: items, createdAt: current.createdAt) : current
        }
        return (nextTabs, nextCursor)
    }

    private static func sortItemsByTag(_ items: [Item]) -> [Item] {
        let counts = tagCounts(items)

        return items.enumerated().sorted { left, right in
            let leftPrimary = primarySortTag(for: left.element, counts: counts)
            let rightPrimary = primarySortTag(for: right.element, counts: counts)

            if left.element.state != right.element.state {
                return left.element.state == .active
            }

            if leftPrimary == nil || rightPrimary == nil {
                if leftPrimary != nil { return true }
                if rightPrimary != nil { return false }
                return left.offset < right.offset
            }

            if leftPrimary!.count != rightPrimary!.count {
                return leftPrimary!.count < rightPrimary!.count
            }

            if leftPrimary!.normalizedName != rightPrimary!.normalizedName {
                return leftPrimary!.normalizedName < rightPrimary!.normalizedName
            }

            return left.offset < right.offset
        }
        .map(\.element)
    }

    private static func tagCounts(_ items: [Item]) -> [String: Int] {
        var counts: [String: Int] = [:]

        for item in items {
            for identity in Set(item.tags.map(\.normalizedName)) {
                counts[identity, default: 0] += 1
            }
        }

        return counts
    }

    private static func primarySortTag(for item: Item, counts: [String: Int]) -> (normalizedName: String, count: Int)? {
        item.tags
            .map { (normalizedName: $0.normalizedName, count: counts[$0.normalizedName, default: .max]) }
            .sorted {
                if $0.count != $1.count {
                    return $0.count < $1.count
                }

                return $0.normalizedName < $1.normalizedName
            }
            .first
    }
}
