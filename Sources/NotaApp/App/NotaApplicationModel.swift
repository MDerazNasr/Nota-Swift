import Foundation
import NotaCore
import Observation

@MainActor
@Observable
final class NotaApplicationModel {
    enum SettingsTab: String, CaseIterable {
        case appearance
        case navigation
        case about
    }

    let persistenceStore: PersistenceStore
    let settingsStore: SettingsStore
    let notesStore: NotesStore
    let windowCoordinator: WindowCoordinator
    var settingsOpen: Bool
    var settingsTab: SettingsTab

    init() {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Nota", isDirectory: true)
        let persistenceStore = PersistenceStore(baseURL: baseURL)
        let settingsStore = SettingsStore(persistenceStore: persistenceStore)
        let notesStore = NotesStore(persistenceStore: persistenceStore)

        self.persistenceStore = persistenceStore
        self.settingsStore = settingsStore
        self.notesStore = notesStore
        self.windowCoordinator = WindowCoordinator()
        self.settingsOpen = false
        self.settingsTab = .appearance
    }

    func start() async {
        async let settings: Void = settingsStore.hydrate()
        async let notes: Void = notesStore.hydrate()
        _ = await (settings, notes)
    }

    func openSettings() {
        settingsTab = .appearance
        settingsOpen = true
    }

    func closeSettings() {
        settingsOpen = false
    }

    func toggleSettings() {
        settingsOpen ? closeSettings() : openSettings()
    }
}
