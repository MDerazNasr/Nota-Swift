import Foundation

@MainActor
public extension NotesStore {
    func createTab() {
        let tab = AppDefaults.makeDefaultTab()
        commit { state in
            state.tabs.append(tab)
            state.activeTabId = tab.id
            state.cursorIndex = -1
            state.editingTabId = tab.id
            state.selectedItemIds = []
        }
    }

    func deleteTab(id: String) {
        commit { state in
            guard let removedIndex = state.tabs.firstIndex(where: { $0.id == id }) else {
                return
            }

            var tabs = state.tabs.filter { $0.id != id }
            if tabs.isEmpty {
                tabs = [AppDefaults.makeDefaultTab()]
            }

            let nextIndex = max(0, removedIndex - 1)
            let nextActiveTabId = state.activeTabId == id ? tabs[min(nextIndex, tabs.count - 1)].id : state.activeTabId
            state.tabs = tabs
            state.activeTabId = nextActiveTabId
            state.cursorIndex = NotesSelectors.cursorForTab(tabs.first(where: { $0.id == nextActiveTabId }))
            state.selectedItemIds = []
            state.tagSortOriginalItemIds.removeValue(forKey: id)
        }
    }

    func setActiveTab(id: String) {
        guard let tab = tabs.first(where: { $0.id == id }) else {
            return
        }

        activeTabId = id
        cursorIndex = NotesSelectors.cursorForTab(tab)
        selectedItemIds = []
    }

    func setEditingTabId(_ id: String?) {
        editingTabId = id
    }

    func reorderTab(id: String, direction: HorizontalDirection) {
        commit { state in
            guard let currentIndex = state.tabs.firstIndex(where: { $0.id == id }) else {
                return
            }

            let targetIndex = direction == .left ? currentIndex - 1 : currentIndex + 1
            guard state.tabs.indices.contains(targetIndex) else {
                return
            }

            let tab = state.tabs.remove(at: currentIndex)
            state.tabs.insert(tab, at: targetIndex)
        }
    }

    func updateTabTitle(id: String, title: String) {
        commit { state in
            state.tabs = state.tabs.map { tab in
                tab.id == id ? Tab(id: tab.id, title: NotesNormalizer.normalizeTitle(title), items: tab.items, createdAt: tab.createdAt) : tab
            }
            if state.editingTabId == id {
                state.editingTabId = nil
            }
        }
    }
}
