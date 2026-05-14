import Foundation

@MainActor
public extension NotesStore {
    func addItemTag(tabId: String, itemId: String, tagName: String) {
        let normalizedName = TagUtilities.normalizeTagName(tagName)
        guard normalizedName.isEmpty == false, TagUtilities.tagKey(normalizedName) != "link" else {
            return
        }

        commit { state in
            let existingTag = TagUtilities.findTag(
                named: normalizedName,
                in: TagUtilities.collectActiveTags(from: state.tabs)
            )
            let tag = existingTag ?? TagUtilities.makeTag(name: normalizedName)

            state.tabs = state.tabs.map { tab in
                guard tab.id == tabId else {
                    return tab
                }

                let items = tab.items.map { item in
                    guard item.id == itemId,
                          TagUtilities.findTag(named: tag.name, in: item.tags) == nil else {
                        return item
                    }

                    return Item(
                        id: item.id,
                        richText: item.richText,
                        state: item.state,
                        tags: item.tags + [tag],
                        createdAt: item.createdAt
                    )
                }

                return Tab(id: tab.id, title: tab.title, items: items, createdAt: tab.createdAt)
            }
        }
    }

    func removeItemTag(tabId: String, itemId: String, tagName: String) {
        let key = TagUtilities.tagKey(tagName)
        guard key.isEmpty == false else {
            return
        }

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
                        richText: item.richText,
                        state: item.state,
                        tags: item.tags.filter { TagUtilities.tagKey($0.name) != key },
                        createdAt: item.createdAt
                    )
                }

                return Tab(id: tab.id, title: tab.title, items: items, createdAt: tab.createdAt)
            }
        }
    }

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
