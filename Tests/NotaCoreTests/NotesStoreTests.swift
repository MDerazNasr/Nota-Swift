import Foundation
import Testing
@testable import NotaCore

@MainActor
struct NotesStoreTests {
    @Test
    func createAndDeleteTabKeepsStateValid() async throws {
        let store = NotesStore(persistenceStore: PersistenceStore(baseURL: try makeTemporaryDirectory()))

        store.createTab()
        #expect(store.tabs.count == 2)
        #expect(store.editingTabId == store.activeTabId)

        let tabId = store.activeTabId
        store.deleteTab(id: tabId)
        #expect(store.tabs.isEmpty == false)
        #expect(store.tabs.contains(where: { $0.id == store.activeTabId }))
    }

    @Test
    func createItemRespectsLimitAndEntersEdit() async throws {
        let store = NotesStore(persistenceStore: PersistenceStore(baseURL: try makeTemporaryDirectory()))

        store.createItem(position: .down, itemLimit: 1)
        store.createItem(position: .down, itemLimit: 1)

        #expect(store.activeTab?.items.count == 1)
        #expect(store.mode == .edit)
    }

    @Test
    func deleteItemClampsCursor() async throws {
        let store = NotesStore(persistenceStore: PersistenceStore(baseURL: try makeTemporaryDirectory()))
        store.createItem(position: .down, itemLimit: 10)
        store.createItem(position: .down, itemLimit: 10)
        let tabId = try #require(store.activeTab?.id)
        let itemId = try #require(store.activeTab?.items[1].id)
        store.setCursorIndex(1)

        store.deleteItem(tabId: tabId, itemId: itemId)

        #expect(store.cursorIndex == 0)
        #expect(store.activeTab?.items.count == 1)
    }

    @Test
    func checkItemMovesDoneItemToBottom() async throws {
        let store = NotesStore(persistenceStore: PersistenceStore(baseURL: try makeTemporaryDirectory()))
        store.createItem(position: .down, itemLimit: 10)
        store.createItem(position: .down, itemLimit: 10)
        let tabId = try #require(store.activeTab?.id)
        let itemId = try #require(store.activeTab?.items[0].id)

        store.checkItem(tabId: tabId, itemId: itemId)

        #expect(store.activeTab?.items.last?.id == itemId)
        #expect(store.activeTab?.items.last?.state == .done)
    }

    @Test
    func sortActiveTabByTagTogglesAndRestoresOrder() async throws {
        let baseURL = try makeTemporaryDirectory()
        let store = NotesStore(persistenceStore: PersistenceStore(baseURL: baseURL))
        let tabId = try #require(store.activeTab?.id)

        for _ in 0..<4 {
            store.createItem(position: .down, itemLimit: 10)
        }

        let ids = try #require(store.activeTab?.items.map(\.id))
        let tags = [
            ItemTag(name: "common", color: "#111", normalizedName: "common"),
            ItemTag(name: "rare", color: "#222", normalizedName: "rare"),
        ]
        store.updateItemRichText(tabId: tabId, itemId: ids[0], richText: CodableRichText(text: "a", spans: []))
        store.commit { state in
            guard let tabIndex = state.tabs.firstIndex(where: { $0.id == tabId }) else { return }
            state.tabs[tabIndex].items[0].tags = [tags[0]]
            state.tabs[tabIndex].items[1].tags = [tags[0], tags[1]]
            state.tabs[tabIndex].items[2].tags = []
            state.tabs[tabIndex].items[3].tags = [tags[0]]
        }

        store.sortActiveTabByTag()
        let sortedIds = try #require(store.activeTab?.items.map(\.id))
        #expect(sortedIds[0] == ids[1])
        #expect(store.tagSortOriginalItemIds[tabId] == ids)

        store.sortActiveTabByTag()
        #expect(store.activeTab?.items.map(\.id) == ids)
        #expect(store.tagSortOriginalItemIds[tabId] == nil)
    }

    @Test
    func undoRestoresPreviousSnapshot() async throws {
        let store = NotesStore(persistenceStore: PersistenceStore(baseURL: try makeTemporaryDirectory()))
        let initialCount = store.tabs.count

        store.createTab()
        store.undoLastChange()

        #expect(store.tabs.count == initialCount)
        #expect(store.mode == .nav)
    }
}

private func makeTemporaryDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}
