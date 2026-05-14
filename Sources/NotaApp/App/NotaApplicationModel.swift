import AppKit
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
    let globalHotKeyManager: GlobalHotKeyManager
    let menuBarController: MenuBarController
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
        self.globalHotKeyManager = GlobalHotKeyManager()
        self.menuBarController = MenuBarController()
        self.settingsOpen = false
        self.settingsTab = .appearance
    }

    func start() async {
        async let settings: Void = settingsStore.hydrate()
        async let notes: Void = notesStore.hydrate()
        _ = await (settings, notes)
        applyBehaviorSettings()
        updateGlobalShortcut()
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

    func updateGlobalShortcut() {
        globalHotKeyManager.register(shortcut: settingsStore.settings.shortcuts.toggleWindow) { [weak self] in
            self?.toggleWindow()
        }
    }

    func toggleWindow() {
        windowCoordinator.toggleWindow()
    }

    func setOpenOnStartup(_ enabled: Bool) {
        settingsStore.setOpenOnStartup(enabled)
        LaunchAtLoginManager.setEnabled(enabled)
    }

    func setShowInDock(_ enabled: Bool) {
        settingsStore.setShowInDock(enabled)
        applyActivationPolicy(showInDock: enabled)
    }

    func setShowInMenuBar(_ enabled: Bool) {
        settingsStore.setShowInMenuBar(enabled)
        menuBarController.setVisible(enabled) { [weak self] in
            self?.toggleWindow()
        }
    }

    func updateShortcut(_ mutation: (inout ShortcutMap) -> Void) {
        settingsStore.updateShortcuts(mutation)
        updateGlobalShortcut()
    }

    private func applyBehaviorSettings() {
        applyActivationPolicy(showInDock: settingsStore.settings.showInDock)
        setShowInMenuBar(settingsStore.settings.showInMenuBar)
        LaunchAtLoginManager.setEnabled(settingsStore.settings.openOnStartup)
    }

    private func applyActivationPolicy(showInDock: Bool) {
        NSApp.setActivationPolicy(showInDock ? .regular : .accessory)
    }
}
