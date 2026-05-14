import Foundation

@MainActor
public extension NotesStore {
    func createItem(position: VerticalDirection, itemLimit: Int) {
        guard let activeTab, activeTab.items.count < itemLimit else {
            return
        }

        let insertionIndex = cursorIndex == -1 ? 0 : cursorIndex + (position == .down ? 1 : 0)
        let item = AppDefaults.makeDefaultItem()

        commit { state in
            state.tabs = state.tabs.map { tab in
                guard tab.id == activeTab.id else {
                    return tab
                }

                return Tab(
                    id: tab.id,
                    title: tab.title,
                    items: NotesItems.insert(item, into: tab.items, at: insertionIndex),
                    createdAt: tab.createdAt
                )
            }
            state.cursorIndex = insertionIndex
            state.mode = .edit
        }
    }

    func updateItemRichText(tabId: String, itemId: String, richText: CodableRichText) {
        commit { state in
            state.tabs = state.tabs.map { tab in
                guard tab.id == tabId else {
                    return tab
                }

                let items = tab.items.map { item in
                    guard item.id == itemId else {
                        return item
                    }

                    return Item(
                        id: item.id,
                        richText: NotesNormalizer.normalize(richText: richText),
                        state: item.state,
                        tags: item.tags,
                        createdAt: item.createdAt
                    )
                }

                return Tab(id: tab.id, title: tab.title, items: items, createdAt: tab.createdAt)
            }
        }
    }

    func deleteItem(tabId: String, itemId: String) {
        commit { state in
            guard let result = NotesItems.removeItemState(
                tabs: state.tabs,
                tabId: tabId,
                itemId: itemId,
                cursorIndex: state.cursorIndex,
                selectedItemIds: state.selectedItemIds
            ) else {
                return
            }

            state.tabs = result.tabs
            state.cursorIndex = result.cursorIndex
            state.selectedItemIds = result.selectedItemIds
        }
    }

    func checkItem(tabId: String, itemId: String) {
        commit { state in
            guard let result = NotesItems.toggleDoneState(
                tabs: state.tabs,
                tabId: tabId,
                itemId: itemId
            ) else {
                return
            }

            state.tabs = result.tabs
            state.cursorIndex = result.cursorIndex
        }
    }

    func sortActiveTabByTag() {
        commit { state in
            guard let activeTab = state.tabs.first(where: { $0.id == state.activeTabId }) else {
                return
            }

            if let originalItemIds = state.tagSortOriginalItemIds[activeTab.id] {
                guard let result = NotesItems.restoreItemsByOrderState(
                    tabs: state.tabs,
                    tabId: activeTab.id,
                    orderedItemIds: originalItemIds,
                    cursorIndex: state.cursorIndex
                ) else {
                    return
                }

                state.tabs = result.tabs
                state.cursorIndex = result.cursorIndex
                state.tagSortOriginalItemIds.removeValue(forKey: activeTab.id)
                return
            }

            guard let result = NotesItems.sortItemsByTagState(
                tabs: state.tabs,
                tabId: activeTab.id,
                cursorIndex: state.cursorIndex
            ) else {
                return
            }

            state.tabs = result.tabs
            state.cursorIndex = result.cursorIndex
            state.tagSortOriginalItemIds[activeTab.id] = activeTab.items.map(\.id)
        }
    }
}
