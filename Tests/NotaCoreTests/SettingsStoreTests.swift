import Foundation
import Testing
@testable import NotaCore

@MainActor
struct SettingsStoreTests {
    @Test
    func settersClampAndPersistNormalizedValues() async throws {
        let store = SettingsStore(persistenceStore: PersistenceStore(baseURL: try makeTemporaryDirectory()))

        store.setFontSize(100)
        store.setBorderRadius(-4)
        store.setItemLimit(1)

        #expect(store.settings.fontSize == 20)
        #expect(store.settings.borderRadius == 0)
        #expect(store.settings.itemLimit == 5)
    }

    @Test
    func shortcutMutationIsNormalized() async throws {
        let store = SettingsStore(persistenceStore: PersistenceStore(baseURL: try makeTemporaryDirectory()))

        store.updateShortcuts {
            $0.toggleWindow = "CommandOrControl+Shift+N"
            $0.renameTab = "CommandOrControl+Shift+R"
            $0.editItem = "Enter"
        }

        #expect(store.settings.shortcuts.toggleWindow == "Alt+Shift+KeyN")
        #expect(store.settings.shortcuts.renameTab.isEmpty)
        #expect(store.settings.shortcuts.editItem == "I")
    }
}

private func makeTemporaryDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}
