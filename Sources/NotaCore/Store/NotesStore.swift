import Foundation
import Observation

@MainActor
@Observable
public final class NotesStore {
    public internal(set) var tabs: [Tab]
    public internal(set) var activeTabId: String
    public internal(set) var cursorIndex: Int
    public internal(set) var mode: AppMode
    public internal(set) var editingTabId: String?
    public internal(set) var selectedItemIds: [String]
    public internal(set) var draggingItemIds: [String]
    public internal(set) var dropTargetTabId: String?
    public internal(set) var itemDropTarget: ItemDropTarget?
    public internal(set) var selectionAnchorId: String?
    public internal(set) var tagSortOriginalItemIds: [String: [String]]
    public internal(set) var hydrated: Bool

    var undoStack: [AppState]
    let persistenceStore: PersistenceStore

    public init(
        persistenceStore: PersistenceStore,
        initialState: AppState = AppDefaults.makeDefaultAppState()
    ) {
        let appState = NotesNormalizer.normalize(appState: initialState)
        self.persistenceStore = persistenceStore
        self.tabs = appState.tabs
        self.activeTabId = appState.activeTabId
        self.cursorIndex = NotesSelectors.cursorForTab(appState.tabs.first)
        self.mode = .nav
        self.editingTabId = nil
        self.selectedItemIds = []
        self.draggingItemIds = []
        self.dropTargetTabId = nil
        self.itemDropTarget = nil
        self.selectionAnchorId = nil
        self.tagSortOriginalItemIds = [:]
        self.hydrated = false
        self.undoStack = []
    }

    public var activeTab: Tab? {
        NotesSelectors.activeTab(in: tabs, activeTabId: activeTabId)
    }

    public func hydrate() async {
        let appState = await persistenceStore.loadNotes()
        tabs = appState.tabs
        activeTabId = appState.activeTabId
        cursorIndex = NotesSelectors.cursorForTab(activeTab)
        hydrated = true
    }

    func commit(_ mutation: (inout MutableState) -> Void) {
        var state = MutableState(
            tabs: tabs,
            activeTabId: activeTabId,
            cursorIndex: cursorIndex,
            mode: mode,
            editingTabId: editingTabId,
            selectedItemIds: selectedItemIds,
            draggingItemIds: draggingItemIds,
            dropTargetTabId: dropTargetTabId,
            itemDropTarget: itemDropTarget,
            selectionAnchorId: selectionAnchorId,
            tagSortOriginalItemIds: tagSortOriginalItemIds
        )
        let previous = state.snapshot
        mutation(&state)
        let next = state.snapshot
        apply(state)

        guard previous != next else {
            return
        }

        undoStack = Array((undoStack + [previous]).suffix(20))
        Task {
            try? await persistenceStore.saveNotes(next)
        }
    }

    func apply(_ state: MutableState) {
        tabs = state.tabs
        activeTabId = state.activeTabId
        cursorIndex = state.cursorIndex
        mode = state.mode
        editingTabId = state.editingTabId
        selectedItemIds = state.selectedItemIds
        draggingItemIds = state.draggingItemIds
        dropTargetTabId = state.dropTargetTabId
        itemDropTarget = state.itemDropTarget
        selectionAnchorId = state.selectionAnchorId
        tagSortOriginalItemIds = state.tagSortOriginalItemIds
    }
}

struct MutableState {
    var tabs: [Tab]
    var activeTabId: String
    var cursorIndex: Int
    var mode: AppMode
    var editingTabId: String?
    var selectedItemIds: [String]
    var draggingItemIds: [String]
    var dropTargetTabId: String?
    var itemDropTarget: ItemDropTarget?
    var selectionAnchorId: String?
    var tagSortOriginalItemIds: [String: [String]]

    var snapshot: AppState {
        AppState(tabs: tabs, activeTabId: activeTabId)
    }
}
