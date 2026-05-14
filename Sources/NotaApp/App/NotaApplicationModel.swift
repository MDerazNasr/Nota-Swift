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
    var settingsFocusIndex: Int
    var settingsCaptureKey: SettingsShortcutCaptureKey?
    var visibleItemIds: [String]

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
        self.settingsFocusIndex = 0
        self.settingsCaptureKey = nil
        self.visibleItemIds = []
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
        settingsFocusIndex = 0
        settingsCaptureKey = nil
        settingsOpen = true
    }

    func closeSettings() {
        settingsCaptureKey = nil
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

    func selectSettingsTab(_ tab: SettingsTab) {
        settingsTab = tab
        settingsFocusIndex = 0
        settingsCaptureKey = nil
    }

    func moveSettingsFocus(offset: Int) {
        settingsFocusIndex = NotaApp.moveSettingsFocus(
            currentIndex: settingsFocusIndex,
            offset: offset,
            itemCount: currentSettingsRows.count
        )
    }

    func moveSettingsTab(offset: Int) {
        selectSettingsTab(NotaApp.moveSettingsTab(current: settingsTab, offset: offset))
    }

    func setSettingsFocusIndex(_ index: Int) {
        guard currentSettingsRows.isEmpty == false else {
            settingsFocusIndex = 0
            return
        }

        settingsFocusIndex = min(max(index, 0), currentSettingsRows.count - 1)
    }

    func activateFocusedSettingsRow() {
        guard let row = currentSettingsRows[safe: settingsFocusIndex] else {
            return
        }

        activate(settingsRow: row)
    }

    func adjustFocusedSettingsRow(offset: Int) {
        guard let row = currentSettingsRows[safe: settingsFocusIndex] else {
            return
        }

        adjust(settingsRow: row, offset: offset)
    }

    func moveFocusedThemeSwatch(offset: Int) {
        guard let row = currentSettingsRows[safe: settingsFocusIndex],
              row.kind == .theme else {
            return
        }

        cycleTheme(offset: offset)
    }

    var currentSettingsRows: [SettingsRowDescriptor] {
        switch settingsTab {
        case .appearance:
            appearanceSettingsRows
        case .navigation:
            navigationSettingsRows
        case .about:
            []
        }
    }

    private func applyBehaviorSettings() {
        applyActivationPolicy(showInDock: settingsStore.settings.showInDock)
        setShowInMenuBar(settingsStore.settings.showInMenuBar)
        LaunchAtLoginManager.setEnabled(settingsStore.settings.openOnStartup)
    }

    private func applyActivationPolicy(showInDock: Bool) {
        NSApp.setActivationPolicy(showInDock ? .regular : .accessory)
    }

    private func activate(settingsRow: SettingsRowDescriptor) {
        switch settingsRow.kind {
        case .theme:
            cycleTheme(offset: 1)
        case .font:
            cycleFont(offset: 1)
        case .fontSize, .borderRadius, .itemLimit, .reference:
            break
        case let .toggle(key):
            toggleBehavior(key)
        case let .hotkey(key):
            settingsCaptureKey = key
        }
    }

    private func adjust(settingsRow: SettingsRowDescriptor, offset: Int) {
        switch settingsRow.kind {
        case .theme:
            cycleTheme(offset: offset)
        case .font:
            cycleFont(offset: offset)
        case .fontSize:
            settingsStore.setFontSize(settingsStore.settings.fontSize + offset)
        case .borderRadius:
            settingsStore.setBorderRadius(settingsStore.settings.borderRadius + offset)
        case .itemLimit:
            settingsStore.setItemLimit(settingsStore.settings.itemLimit + offset)
        case let .toggle(key):
            setBehavior(key, enabled: offset > 0)
        case .hotkey, .reference:
            break
        }
    }

    private func cycleTheme(offset: Int) {
        let themes = ThemeCatalog.orderedThemes
        guard let currentIndex = themes.firstIndex(where: { $0.key == settingsStore.settings.theme }) else {
            settingsStore.setTheme(themes[0].key)
            return
        }

        let nextIndex = (currentIndex + offset + themes.count) % themes.count
        settingsStore.setTheme(themes[nextIndex].key)
    }

    private func cycleFont(offset: Int) {
        let fonts = FontOption.allCases
        guard let currentIndex = fonts.firstIndex(of: settingsStore.settings.font) else {
            settingsStore.setFont(fonts[0])
            return
        }

        let nextIndex = min(max(currentIndex + offset, 0), fonts.count - 1)
        settingsStore.setFont(fonts[nextIndex])
    }

    private func toggleBehavior(_ key: SettingsBehaviorKey) {
        switch key {
        case .openOnStartup:
            setOpenOnStartup(settingsStore.settings.openOnStartup == false)
        case .showInDock:
            setShowInDock(settingsStore.settings.showInDock == false)
        case .showInMenuBar:
            setShowInMenuBar(settingsStore.settings.showInMenuBar == false)
        }
    }

    private func setBehavior(_ key: SettingsBehaviorKey, enabled: Bool) {
        switch key {
        case .openOnStartup:
            setOpenOnStartup(enabled)
        case .showInDock:
            setShowInDock(enabled)
        case .showInMenuBar:
            setShowInMenuBar(enabled)
        }
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
