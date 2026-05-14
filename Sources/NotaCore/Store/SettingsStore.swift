import Foundation
import Observation

@MainActor
@Observable
public final class SettingsStore {
    public internal(set) var settings: Settings
    public internal(set) var hydrated: Bool

    let persistenceStore: PersistenceStore

    public init(
        persistenceStore: PersistenceStore,
        initialSettings: Settings = AppDefaults.defaultSettings
    ) {
        self.persistenceStore = persistenceStore
        self.settings = SettingsNormalizer.normalize(settings: initialSettings)
        self.hydrated = false
    }

    public func hydrate() async {
        settings = await persistenceStore.loadSettings()
        hydrated = true
    }

    public func setTheme(_ theme: String) {
        settings.theme = theme
        queueSave()
    }

    public func setFont(_ font: FontOption) {
        settings.font = font
        queueSave()
    }

    public func setFontSize(_ value: Int) {
        settings.fontSize = value
        queueSave()
    }

    public func setBorderRadius(_ value: Int) {
        settings.borderRadius = value
        queueSave()
    }

    public func setItemLimit(_ value: Int) {
        settings.itemLimit = value
        queueSave()
    }

    public func setOpenOnStartup(_ value: Bool) {
        settings.openOnStartup = value
        queueSave()
    }

    public func setShowInDock(_ value: Bool) {
        settings.showInDock = value
        queueSave()
    }

    public func setShowInMenuBar(_ value: Bool) {
        settings.showInMenuBar = value
        queueSave()
    }

    public func setWindowPosition(_ value: WindowPosition?) {
        settings.windowPosition = value
        queueSave()
    }

    public func setWindowSize(_ value: WindowSize?) {
        settings.windowSize = value
        queueSave()
    }

    public func updateShortcuts(_ mutation: (inout ShortcutMap) -> Void) {
        mutation(&settings.shortcuts)
        queueSave()
    }

    private func queueSave() {
        settings = SettingsNormalizer.normalize(settings: settings)
        let snapshot = settings
        Task {
            try? await persistenceStore.saveSettings(snapshot)
        }
    }
}
