import Foundation
import NotaCore
import Observation

@MainActor
@Observable
final class NotaApplicationModel {
    let persistenceStore: PersistenceStore
    let settingsStore: SettingsStore
    let notesStore: NotesStore
    let windowCoordinator: WindowCoordinator

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
    }

    func start() async {
        async let settings: Void = settingsStore.hydrate()
        async let notes: Void = notesStore.hydrate()
        _ = await (settings, notes)
    }
}
