import AppKit
import NotaCore
import SwiftUI

struct AppKeyMonitor: ViewModifier {
    @Environment(NotaApplicationModel.self) private var model
    @State private var monitor: Any?
    @State private var navCommandBuffer = NavCommandBuffer()

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
            navCommandBuffer.clear()
            model.notesStore.createTab()
            return true
        }

        if shortcut == shortcuts.deleteTab {
            navCommandBuffer.clear()
            model.notesStore.deleteTab(id: model.notesStore.activeTabId)
            return true
        }

        if shortcut == shortcuts.checkItem,
           let focused = focusedItem {
            navCommandBuffer.clear()
            model.notesStore.checkItem(tabId: focused.tabId, itemId: focused.item.id)
            return true
        }

        if shortcut == shortcuts.openItemLink {
            navCommandBuffer.clear()
            if let focused = focusedItem,
               let urlString = focused.item.richText.firstLinkURLString,
               let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }
            return true
        }

        if shortcut == shortcuts.sortByTag {
            navCommandBuffer.clear()
            model.notesStore.sortActiveTabByTag()
            return true
        }

        if shortcut == shortcuts.deleteItem,
           let focused = focusedItem {
            navCommandBuffer.clear()
            model.notesStore.deleteItem(tabId: focused.tabId, itemId: focused.item.id)
            return true
        }

        if shortcut == shortcuts.enterMoveMode {
            navCommandBuffer.clear()
            model.notesStore.enterMoveMode()
            return true
        }

        if shortcut == shortcuts.editItem {
            navCommandBuffer.clear()
            model.notesStore.setMode(.edit)
            return true
        }

        if shortcut == shortcuts.moveTabLeft {
            navCommandBuffer.clear()
            model.notesStore.reorderTab(id: model.notesStore.activeTabId, direction: .left)
            return true
        }

        if shortcut == shortcuts.moveTabRight {
            navCommandBuffer.clear()
            model.notesStore.reorderTab(id: model.notesStore.activeTabId, direction: .right)
            return true
        }

        if shortcut == shortcuts.undo {
            navCommandBuffer.clear()
            model.notesStore.undoLastChange()
            return true
        }

        if handleNumberedTabShortcut(event) {
            navCommandBuffer.clear()
            return true
        }

        switch event.charactersIgnoringModifiers {
        case "j":
            navCommandBuffer.clear()
            model.notesStore.moveCursor(.down)
            return true
        case "k":
            navCommandBuffer.clear()
            if model.notesStore.cursorIndex <= 0 {
                model.notesStore.setMode(.tabs)
            } else {
                model.notesStore.moveCursor(.up)
            }
            return true
        case "H":
            navCommandBuffer.clear()
            jumpCursor(to: .top)
            return true
        case "M":
            navCommandBuffer.clear()
            jumpCursor(to: .middle)
            return true
        case "L":
            navCommandBuffer.clear()
            jumpCursor(to: .bottom)
            return true
        case "h":
            navCommandBuffer.clear()
            switchTab(offset: -1)
            return true
        case "l":
            navCommandBuffer.clear()
            switchTab(offset: 1)
            return true
        case "d":
            var buffer = navCommandBuffer
            let shouldDelete = buffer.registerDelete(now: CFAbsoluteTimeGetCurrent())
            navCommandBuffer = buffer
            if let focused = focusedItem,
               shouldDelete {
                model.notesStore.deleteItem(tabId: focused.tabId, itemId: focused.item.id)
            }
            return true
        default:
            navCommandBuffer.clear()
            break
        }

        switch event.characters {
        case "o":
            navCommandBuffer.clear()
            model.notesStore.createItem(position: .down, itemLimit: model.settingsStore.settings.itemLimit)
            return true
        case "O":
            navCommandBuffer.clear()
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
        if model.settingsCaptureKey != nil {
            return false
        }

        if event.keyCode == 53 {
            model.closeSettings()
            return true
        }

        switch event.charactersIgnoringModifiers {
        case "j":
            model.moveSettingsFocus(offset: 1)
            return true
        case "k":
            model.moveSettingsFocus(offset: -1)
            return true
        case "h":
            model.moveSettingsTab(offset: -1)
            return true
        case "l":
            model.moveSettingsTab(offset: 1)
            return true
        default:
            break
        }

        switch event.keyCode {
        case 36, 49, 76:
            model.activateFocusedSettingsRow()
            return true
        case 123:
            model.adjustFocusedSettingsRow(offset: -1)
            return true
        case 124:
            model.adjustFocusedSettingsRow(offset: 1)
            return true
        case 125:
            model.moveFocusedThemeSwatch(offset: 5)
            return true
        case 126:
            model.moveFocusedThemeSwatch(offset: -5)
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

    private func handleNumberedTabShortcut(_ event: NSEvent) -> Bool {
        guard event.modifierFlags.contains(.command),
              let characters = event.charactersIgnoringModifiers,
              let tabNumber = Int(characters),
              tabNumber >= 1,
              tabNumber <= 9 else {
            return false
        }

        let index = tabNumber - 1
        guard model.notesStore.tabs.indices.contains(index) else {
            return true
        }

        model.notesStore.setActiveTab(id: model.notesStore.tabs[index].id)
        return true
    }

    private func jumpCursor(to position: VisibleCursorPosition) {
        guard let activeTab = model.notesStore.activeTab,
              let index = visibleCursorIndex(
                orderedVisibleItemIds: model.visibleItemIds,
                items: activeTab.items,
                position: position
              ) else {
            return
        }

        model.notesStore.setCursorIndex(index)
    }
}
