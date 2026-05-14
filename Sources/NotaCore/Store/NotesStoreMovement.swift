import Foundation

@MainActor
public extension NotesStore {
    func setSelectedItemIds(_ ids: [String]) {
        selectedItemIds = ids
    }

    func toggleItemSelection(_ itemId: String) {
        var selected = Set(selectedItemIds)
        if selected.contains(itemId) {
            selected.remove(itemId)
        } else {
            selected.insert(itemId)
        }
        selectedItemIds = Array(selected)
        mode = .nav
    }

    func enterMoveMode() {
        guard let activeTab, activeTab.items.indices.contains(cursorIndex) else {
            return
        }

        let itemId = activeTab.items[cursorIndex].id
        selectedItemIds = selectedItemIds.contains(itemId) ? selectedItemIds : [itemId]
        selectionAnchorId = itemId
        mode = .move
    }

    func exitMoveMode() {
        mode = .nav
        selectedItemIds = []
        selectionAnchorId = nil
        itemDropTarget = nil
    }

    func extendMoveSelection(direction: VerticalDirection, range: Bool) {
        guard let result = NotesMovement.buildMoveSelectionState(
            tabs: tabs,
            activeTabId: activeTabId,
            cursorIndex: cursorIndex,
            selectedItemIds: selectedItemIds,
            selectionAnchorId: selectionAnchorId,
            direction: direction,
            range: range
        ) else {
            return
        }

        cursorIndex = result.cursorIndex
        selectedItemIds = result.selectedItemIds
        selectionAnchorId = result.selectionAnchorId
        mode = .move
    }

    func reorderMoveSelection(direction: VerticalDirection) {
        commit { state in
            guard let result = NotesMovement.reorderSelectedItems(
                tabs: state.tabs,
                activeTabId: state.activeTabId,
                selectedItemIds: state.selectedItemIds,
                direction: direction
            ) else {
                return
            }

            state.tabs = result.tabs
            state.cursorIndex = result.cursorIndex
            state.mode = .move
        }
    }

    func moveSelectionToAdjacentTab(direction: HorizontalDirection, itemLimit: Int) {
        commit { state in
            guard let currentIndex = state.tabs.firstIndex(where: { $0.id == state.activeTabId }) else {
                return
            }

            let targetIndex = currentIndex + (direction == .right ? 1 : -1)
            guard state.tabs.indices.contains(targetIndex) else {
                return
            }

            let targetTabId = state.tabs[targetIndex].id
            guard let result = NotesMovement.buildMoveItemsState(
                tabs: state.tabs,
                activeTabId: state.activeTabId,
                itemIds: state.selectedItemIds,
                targetTabId: targetTabId,
                itemLimit: itemLimit
            ) else {
                return
            }

            state.tabs = result.tabs
            state.activeTabId = result.activeTabId
            state.cursorIndex = result.cursorIndex
            state.selectedItemIds = result.movedIds
            state.selectionAnchorId = result.movedIds.first
            state.mode = .move
        }
    }

    func deleteSelectedItems() {
        commit { state in
            let selected = Set(state.selectedItemIds)
            guard selected.isEmpty == false else {
                return
            }

            state.tabs = state.tabs.map { tab in
                Tab(id: tab.id, title: tab.title, items: tab.items.filter { selected.contains($0.id) == false }, createdAt: tab.createdAt)
            }
            state.cursorIndex = NotesSelectors.clampCursor(state.cursorIndex, in: state.tabs.first(where: { $0.id == state.activeTabId }))
            state.mode = .nav
            state.selectedItemIds = []
            state.selectionAnchorId = nil
        }
    }

    func setCursorIndex(_ index: Int) {
        cursorIndex = NotesSelectors.clampCursor(index, in: activeTab)
    }

    func moveCursor(_ direction: VerticalDirection) {
        guard let activeTab, activeTab.items.isEmpty == false else {
            cursorIndex = -1
            return
        }

        let offset = direction == .down ? 1 : -1
        cursorIndex = (cursorIndex + offset + activeTab.items.count) % activeTab.items.count
    }

    func setMode(_ mode: AppMode) {
        self.mode = mode
    }

    func startItemDrag(_ itemIds: [String]) {
        draggingItemIds = itemIds
        dropTargetTabId = nil
        itemDropTarget = nil
        mode = .nav
    }

    func setDropTargetTabId(_ id: String?) {
        dropTargetTabId = id
    }

    func setItemDropTarget(_ target: ItemDropTarget?) {
        itemDropTarget = target
    }

    func finishItemDrag(targetTabId: String?, itemLimit: Int) {
        guard let targetTabId else {
            draggingItemIds = []
            dropTargetTabId = nil
            itemDropTarget = nil
            return
        }

        commit { state in
            guard let result = NotesMovement.buildMoveItemsState(
                tabs: state.tabs,
                activeTabId: state.activeTabId,
                itemIds: state.draggingItemIds,
                targetTabId: targetTabId,
                itemLimit: itemLimit
            ) else {
                state.draggingItemIds = []
                state.dropTargetTabId = nil
                state.itemDropTarget = nil
                return
            }

            state.tabs = result.tabs
            state.activeTabId = result.activeTabId
            state.cursorIndex = result.cursorIndex
            state.draggingItemIds = []
            state.dropTargetTabId = nil
            state.itemDropTarget = nil
        }
    }

    func finishItemDrag(at target: ItemDropTarget?) {
        guard let target else {
            draggingItemIds = []
            dropTargetTabId = nil
            itemDropTarget = nil
            return
        }

        commit { state in
            guard let result = NotesMovement.buildReorderItemsState(
                tabs: state.tabs,
                activeTabId: state.activeTabId,
                itemIds: state.draggingItemIds,
                target: target
            ) else {
                state.draggingItemIds = []
                state.dropTargetTabId = nil
                state.itemDropTarget = nil
                return
            }

            state.tabs = result.tabs
            state.activeTabId = result.activeTabId
            state.cursorIndex = result.cursorIndex
            state.draggingItemIds = []
            state.dropTargetTabId = nil
            state.itemDropTarget = nil
        }
    }

    func cancelItemDrag() {
        draggingItemIds = []
        dropTargetTabId = nil
        itemDropTarget = nil
    }

    func undoLastChange() {
        guard let previous = undoStack.last else {
            return
        }

        undoStack.removeLast()
        tabs = previous.tabs
        activeTabId = previous.activeTabId
        cursorIndex = NotesSelectors.cursorForTab(activeTab)
        mode = .nav
        selectedItemIds = []
        draggingItemIds = []
        dropTargetTabId = nil
        itemDropTarget = nil
        selectionAnchorId = nil
        tagSortOriginalItemIds = [:]

        Task {
            try? await persistenceStore.saveNotes(previous)
        }
    }
}
