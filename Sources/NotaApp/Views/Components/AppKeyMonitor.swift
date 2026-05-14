import AppKit
import NotaCore
import SwiftUI

struct AppKeyMonitor: ViewModifier {
    @Environment(NotaApplicationModel.self) private var model
    @State private var monitor: Any?

    func body(content: Content) -> some View {
        content
            .onAppear {
                monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    handle(event) ? nil : event
                }
            }
            .onDisappear {
                if let monitor {
                    NSEvent.removeMonitor(monitor)
                }
            }
    }

    private func handle(_ event: NSEvent) -> Bool {
        let shortcut = EventShortcutFormatter.format(event)
        let shortcuts = model.settingsStore.settings.shortcuts
        let isEditingText = event.window?.firstResponder is NSTextView

        if shortcut == shortcuts.openSettings {
            model.notesStore.setMode(.nav)
            model.toggleSettings()
            return true
        }

        if model.settingsOpen {
            return handleSettings(event)
        }

        if isEditingText {
            return false
        }

        if model.notesStore.mode == .tabMove {
            return handleTabMoveMode(event)
        }

        if model.notesStore.mode == .move {
            return handleMoveMode(event)
        }

        if model.notesStore.mode == .tabs {
            return handleTabsMode(event)
        }

        guard model.notesStore.mode == .nav else {
            return false
        }

        if shortcut == shortcuts.newTab {
            model.notesStore.createTab()
            return true
        }

        if shortcut == shortcuts.deleteTab {
            model.notesStore.deleteTab(id: model.notesStore.activeTabId)
            return true
        }

        if shortcut == shortcuts.checkItem,
           let focused = focusedItem {
            model.notesStore.checkItem(tabId: focused.tabId, itemId: focused.item.id)
            return true
        }

        if shortcut == shortcuts.openItemLink {
            if let focused = focusedItem,
               let urlString = focused.item.richText.firstLinkURLString,
               let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }
            return true
        }

        if shortcut == shortcuts.sortByTag {
            model.notesStore.sortActiveTabByTag()
            return true
        }

        if shortcut == shortcuts.deleteItem,
           let focused = focusedItem {
            model.notesStore.deleteItem(tabId: focused.tabId, itemId: focused.item.id)
            return true
        }

        if shortcut == shortcuts.enterMoveMode {
            model.notesStore.enterMoveMode()
            return true
        }

        if shortcut == shortcuts.editItem {
            model.notesStore.setMode(.edit)
            return true
        }

        if shortcut == shortcuts.moveTabLeft {
            model.notesStore.reorderTab(id: model.notesStore.activeTabId, direction: .left)
            return true
        }

        if shortcut == shortcuts.moveTabRight {
            model.notesStore.reorderTab(id: model.notesStore.activeTabId, direction: .right)
            return true
        }

        if shortcut == shortcuts.undo {
            model.notesStore.undoLastChange()
            return true
        }

        switch event.charactersIgnoringModifiers {
        case "j":
            model.notesStore.moveCursor(.down)
            return true
        case "k":
            if model.notesStore.cursorIndex <= 0 {
                model.notesStore.setMode(.tabs)
            } else {
                model.notesStore.moveCursor(.up)
            }
            return true
        case "h":
            switchTab(offset: -1)
            return true
        case "l":
            switchTab(offset: 1)
            return true
        default:
            break
        }

        switch event.characters {
        case "o":
            model.notesStore.createItem(position: .down, itemLimit: model.settingsStore.settings.itemLimit)
            return true
        case "O":
            model.notesStore.createItem(position: .up, itemLimit: model.settingsStore.settings.itemLimit)
            return true
        default:
            return false
        }
    }

    private var focusedItem: (tabId: String, item: NotaCore.Item)? {
        guard let activeTab = model.notesStore.activeTab,
              activeTab.items.indices.contains(model.notesStore.cursorIndex) else {
            return nil
        }

        return (activeTab.id, activeTab.items[model.notesStore.cursorIndex])
    }

    private func handleSettings(_ event: NSEvent) -> Bool {
        if event.keyCode == 53 {
            model.closeSettings()
            return true
        }

        switch event.charactersIgnoringModifiers {
        case "h":
            moveSettingsTab(offset: -1)
            return true
        case "l":
            moveSettingsTab(offset: 1)
            return true
        default:
            return false
        }
    }

    private func handleTabsMode(_ event: NSEvent) -> Bool {
        switch event.charactersIgnoringModifiers {
        case "h":
            switchTab(offset: -1)
            return true
        case "l":
            switchTab(offset: 1)
            return true
        case "i":
            model.notesStore.setEditingTabId(model.notesStore.activeTabId)
            return true
        case "j":
            model.notesStore.setMode(.nav)
            return true
        case "\u{1b}":
            model.notesStore.setMode(.nav)
            return true
        default:
            break
        }

        if event.keyCode == 49 {
            model.notesStore.setMode(.tabMove)
            return true
        }

        return false
    }

    private func handleTabMoveMode(_ event: NSEvent) -> Bool {
        switch event.charactersIgnoringModifiers {
        case "h":
            model.notesStore.reorderTab(id: model.notesStore.activeTabId, direction: .left)
            return true
        case "l":
            model.notesStore.reorderTab(id: model.notesStore.activeTabId, direction: .right)
            return true
        case "\u{1b}":
            model.notesStore.setMode(.tabs)
            return true
        default:
            break
        }

        if event.keyCode == 49 {
            model.notesStore.setMode(.tabs)
            return true
        }

        return false
    }

    private func handleMoveMode(_ event: NSEvent) -> Bool {
        switch event.charactersIgnoringModifiers {
        case " ":
            model.notesStore.exitMoveMode()
            return true
        case "u", "U":
            model.notesStore.undoLastChange()
            return true
        case "d", "D":
            model.notesStore.deleteSelectedItems()
            return true
        case "j":
            if event.modifierFlags.contains(.shift) {
                model.notesStore.extendMoveSelection(direction: .down, range: true)
            } else if event.modifierFlags.contains(.command) {
                model.notesStore.extendMoveSelection(direction: .down, range: false)
            } else {
                model.notesStore.reorderMoveSelection(direction: .down)
            }
            return true
        case "k":
            if event.modifierFlags.contains(.shift) {
                model.notesStore.extendMoveSelection(direction: .up, range: true)
            } else if event.modifierFlags.contains(.command) {
                model.notesStore.extendMoveSelection(direction: .up, range: false)
            } else {
                model.notesStore.reorderMoveSelection(direction: .up)
            }
            return true
        case "h":
            model.notesStore.moveSelectionToAdjacentTab(direction: .left, itemLimit: model.settingsStore.settings.itemLimit)
            return true
        case "l":
            model.notesStore.moveSelectionToAdjacentTab(direction: .right, itemLimit: model.settingsStore.settings.itemLimit)
            return true
        default:
            return false
        }
    }

    private func switchTab(offset: Int) {
        guard let currentIndex = model.notesStore.tabs.firstIndex(where: { $0.id == model.notesStore.activeTabId }),
              model.notesStore.tabs.isEmpty == false else {
            return
        }

        let nextIndex = (currentIndex + offset + model.notesStore.tabs.count) % model.notesStore.tabs.count
        model.notesStore.setActiveTab(id: model.notesStore.tabs[nextIndex].id)
    }

    private func moveSettingsTab(offset: Int) {
        let tabs = NotaApplicationModel.SettingsTab.allCases
        guard let currentIndex = tabs.firstIndex(of: model.settingsTab) else {
            return
        }

        let nextIndex = (currentIndex + offset + tabs.count) % tabs.count
        model.settingsTab = tabs[nextIndex]
    }
}
