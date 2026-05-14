import Foundation
import Testing
@testable import NotaCore

struct PersistenceStoreTests {
    @Test
    func missingFilesReturnDefaults() async throws {
        let directory = try makeTemporaryDirectory()
        let store = PersistenceStore(baseURL: directory)

        let notes = await store.loadNotes()
        let settings = await store.loadSettings()

        #expect(notes.tabs.count == 1)
        #expect(notes.activeTabId == notes.tabs[0].id)
        #expect(settings.theme == "dark-zinc")
        #expect(settings.font == .jetBrainsMono)
    }

    @Test
    func notesLoadIsNormalized() async throws {
        let directory = try makeTemporaryDirectory()
        let store = PersistenceStore(baseURL: directory)
        let broken = AppState(
            tabs: [
                Tab(
                    id: "tab-1",
                    title: "   ",
                    items: [
                        Item(
                            id: "item-1",
                            richText: CodableRichText(
                                text: "Task",
                                spans: [RichTextSpan(start: 0, end: 99, link: "https://example.com")]
                            ),
                            state: .active,
                            tags: [ItemTag(name: "  demo   tag  ", color: "#fff", normalizedName: "")],
                            createdAt: 1
                        )
                    ],
                    createdAt: 1
                )
            ],
            activeTabId: "missing"
        )

        try await store.saveNotes(broken)
        let loaded = await store.loadNotes()

        #expect(loaded.activeTabId == "tab-1")
        #expect(loaded.tabs[0].title == "Untitled")
        #expect(loaded.tabs[0].items[0].richText.spans[0].end == 4)
        #expect(loaded.tabs[0].items[0].tags[0].name == "demo tag")
        #expect(loaded.tabs[0].items[0].tags[0].normalizedName == "demo tag")
    }

    @Test
    func settingsLoadMigratesLegacyShortcutsAndWindowSize() async throws {
        let directory = try makeTemporaryDirectory()
        let store = PersistenceStore(baseURL: directory)
        let settings = Settings(
            theme: "dark-zinc",
            font: .jetBrainsMono,
            fontSize: 13,
            borderRadius: 8,
            itemLimit: 15,
            openOnStartup: false,
            showInDock: true,
            showInMenuBar: false,
            shortcuts: ShortcutMap(
                toggleWindow: "Alt+Shift+N",
                newTab: "CommandOrControl+T",
                deleteTab: "CommandOrControl+W",
                openSettings: "CommandOrControl+,",
                checkItem: "CommandOrControl+Enter",
                renameTab: "CommandOrControl+Shift+R",
                moveTabLeft: "Shift+<",
                moveTabRight: "Shift+>",
                createItemBelow: "O",
                createItemAbove: "Shift+O",
                editItem: "Enter",
                deleteItem: "Delete",
                enterMoveMode: "Space",
                undo: "U",
                openItemLink: "CommandOrControl+X",
                sortByTag: "CommandOrControl+."
            ),
            windowPosition: WindowPosition(x: 10, y: 10),
            windowSize: WindowSize(width: 380, height: 500)
        )

        try await store.saveSettings(settings)
        let loaded = await store.loadSettings()

        #expect(loaded.shortcuts.toggleWindow == "Alt+Shift+KeyN")
        #expect(loaded.shortcuts.renameTab.isEmpty)
        #expect(loaded.shortcuts.editItem == "I")
        #expect(loaded.windowSize?.height == 560)
    }

    @Test
    func corruptSettingsFallbackToDefaults() async throws {
        let directory = try makeTemporaryDirectory()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("bad".utf8).write(to: directory.appendingPathComponent(AppDefaults.settingsFileName))
        let store = PersistenceStore(baseURL: directory)

        let settings = await store.loadSettings()

        #expect(settings.shortcuts.toggleWindow == AppDefaults.defaultShortcuts.toggleWindow)
        #expect(settings.itemLimit == AppDefaults.defaultSettings.itemLimit)
    }
}

private func makeTemporaryDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}
