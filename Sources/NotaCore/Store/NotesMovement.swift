import Foundation

public enum DropPosition: String, Codable, Equatable, Sendable {
    case before
    case after
}

public struct ItemDropTarget: Equatable, Sendable {
    public var tabId: String
    public var itemId: String
    public var position: DropPosition

    public init(tabId: String, itemId: String, position: DropPosition) {
        self.tabId = tabId
        self.itemId = itemId
        self.position = position
    }
}

public enum NotesMovement {
    public static func buildMoveSelectionState(
        tabs: [Tab],
        activeTabId: String,
        cursorIndex: Int,
        selectedItemIds: [String],
        selectionAnchorId: String?,
        direction: VerticalDirection,
        range: Bool
    ) -> (cursorIndex: Int, selectedItemIds: [String], selectionAnchorId: String?)? {
        guard let tab = tabs.first(where: { $0.id == activeTabId }),
              tab.items.isEmpty == false else {
            return nil
        }

        let nextCursor = NotesSelectors.clampCursor(cursorIndex + (direction == .down ? 1 : -1), in: tab)
        let itemId = tab.items[nextCursor].id

        if range, let selectionAnchorId, let anchorIndex = tab.items.firstIndex(where: { $0.id == selectionAnchorId }) {
            let bounds = anchorIndex <= nextCursor ? anchorIndex...nextCursor : nextCursor...anchorIndex
            let ids = bounds.map { tab.items[$0].id }
            return (nextCursor, ids, selectionAnchorId)
        }

        var nextSelected = Set(selectedItemIds)
        if nextSelected.contains(itemId) {
            nextSelected.remove(itemId)
        } else {
            nextSelected.insert(itemId)
        }
        return (nextCursor, Array(nextSelected), selectionAnchorId ?? itemId)
    }

    public static func reorderSelectedItems(
        tabs: [Tab],
        activeTabId: String,
        selectedItemIds: [String],
        direction: VerticalDirection
    ) -> (tabs: [Tab], cursorIndex: Int)? {
        guard let tab = tabs.first(where: { $0.id == activeTabId }) else {
            return nil
        }

        let selected = Set(selectedItemIds)
        guard selected.isEmpty == false else {
            return nil
        }

        let selectedIndices = tab.items.enumerated().compactMap { selected.contains($0.element.id) ? $0.offset : nil }
        guard selectedIndices.isEmpty == false else {
            return nil
        }

        if direction == .up, selectedIndices.first == 0 {
            return nil
        }

        if direction == .down, selectedIndices.last == tab.items.count - 1 {
            return nil
        }

        var items = tab.items
        let movingItems = selectedIndices.map { items[$0] }
        for index in selectedIndices.reversed() {
            items.remove(at: index)
        }

        let insertionIndex = direction == .up ? selectedIndices[0] - 1 : selectedIndices[0] + 1
        items.insert(contentsOf: movingItems, at: insertionIndex)
        let nextTabs = tabs.map { current in
            current.id == activeTabId ? Tab(id: current.id, title: current.title, items: items, createdAt: current.createdAt) : current
        }
        return (nextTabs, insertionIndex)
    }

    public static func buildMoveItemsState(
        tabs: [Tab],
        activeTabId: String,
        itemIds: [String],
        targetTabId: String,
        itemLimit: Int
    ) -> (tabs: [Tab], activeTabId: String, cursorIndex: Int, movedIds: [String])? {
        guard let targetTab = tabs.first(where: { $0.id == targetTabId }) else {
            return nil
        }

        let selectedIds = Set(itemIds)
        guard selectedIds.isEmpty == false else {
            return nil
        }

        let movableItems = tabs.flatMap(\.items).filter { selectedIds.contains($0.id) }
        guard movableItems.isEmpty == false else {
            return nil
        }

        let targetSelectedCount = targetTab.items.filter { selectedIds.contains($0.id) }.count
        let capacity = max(0, itemLimit - targetTab.items.count + targetSelectedCount)
        let itemsToMove = Array(movableItems.prefix(capacity))
        guard itemsToMove.isEmpty == false else {
            return nil
        }

        let movedIds = Set(itemsToMove.map(\.id))
        let nextTabs = tabs.map { tab in
            let remainingItems = tab.items.filter { movedIds.contains($0.id) == false }
            guard tab.id == targetTabId else {
                return Tab(id: tab.id, title: tab.title, items: remainingItems, createdAt: tab.createdAt)
            }

            return Tab(id: tab.id, title: tab.title, items: remainingItems + itemsToMove, createdAt: tab.createdAt)
        }
        let nextTargetTab = nextTabs.first(where: { $0.id == targetTabId })
        let cursorIndex = NotesSelectors.cursorForTab(nextTargetTab)
        return (nextTabs, targetTabId, cursorIndex, itemsToMove.map(\.id))
    }

    public static func buildReorderItemsState(
        tabs: [Tab],
        activeTabId: String,
        itemIds: [String],
        target: ItemDropTarget
    ) -> (tabs: [Tab], activeTabId: String, cursorIndex: Int)? {
        guard let tab = tabs.first(where: { $0.id == target.tabId }) else {
            return nil
        }

        let selectedIds = Set(itemIds)
        guard selectedIds.isEmpty == false, selectedIds.contains(target.itemId) == false else {
            return nil
        }

        let itemsToMove = tab.items.filter { selectedIds.contains($0.id) }
        guard itemsToMove.isEmpty == false else {
            return nil
        }

        let remainingItems = tab.items.filter { selectedIds.contains($0.id) == false }
        guard let targetIndex = remainingItems.firstIndex(where: { $0.id == target.itemId }) else {
            return nil
        }

        let insertionIndex = target.position == .after ? targetIndex + 1 : targetIndex
        var nextItems = remainingItems
        nextItems.insert(contentsOf: itemsToMove, at: insertionIndex)
        let nextTabs = tabs.map { current in
            current.id == target.tabId ? Tab(id: current.id, title: current.title, items: nextItems, createdAt: current.createdAt) : current
        }
        return (nextTabs, activeTabId == target.tabId ? activeTabId : target.tabId, insertionIndex)
    }
}
