import Foundation

public enum AppDefaults {
    public static let notesFileName = "notes.json"
    public static let settingsFileName = "settings.json"
    public static let saveDelayNanoseconds: UInt64 = 300_000_000

    public static let defaultWindowWidth = 380.0
    public static let defaultWindowHeight = 560.0
    public static let legacyWindowHeight = 500.0

    public static let defaultShortcuts = ShortcutMap(
        toggleWindow: "Alt+Shift+KeyN",
        newTab: "CommandOrControl+T",
        deleteTab: "CommandOrControl+W",
        openSettings: "CommandOrControl+,",
        checkItem: "CommandOrControl+Enter",
        renameTab: "",
        moveTabLeft: "Shift+<",
        moveTabRight: "Shift+>",
        createItemBelow: "O",
        createItemAbove: "Shift+O",
        editItem: "I",
        deleteItem: "Delete",
        enterMoveMode: "Space",
        undo: "U",
        openItemLink: "CommandOrControl+X",
        sortByTag: "CommandOrControl+."
    )

    public static let defaultSettings = Settings(
        theme: "dark-zinc",
        font: .jetBrainsMono,
        fontSize: 13,
        borderRadius: 8,
        itemLimit: 15,
        openOnStartup: false,
        showInDock: true,
        showInMenuBar: false,
        shortcuts: defaultShortcuts
    )

    public static func makeDefaultTab(
        id: String = makeID(),
        title: String = "Untitled",
        createdAt: TimeInterval = Date().timeIntervalSince1970
    ) -> Tab {
        Tab(id: id, title: title, items: [], createdAt: createdAt)
    }

    public static func makeDefaultItem(
        id: String = makeID(),
        createdAt: TimeInterval = Date().timeIntervalSince1970
    ) -> Item {
        Item(id: id, richText: .empty, state: .active, tags: [], createdAt: createdAt)
    }

    public static func makeDefaultAppState() -> AppState {
        let tab = makeDefaultTab()
        return AppState(tabs: [tab], activeTabId: tab.id)
    }

    public static func makeID() -> String {
        String(UUID().uuidString.prefix(10))
    }
}
