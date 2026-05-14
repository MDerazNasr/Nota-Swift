import NotaCore
import SwiftUI

struct NavigationTabView: View {
    @Environment(NotaApplicationModel.self) private var model
    @State private var captureKey: ShortcutCaptureKey?

    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            section("Behavior") {
                toggleRow("Open on startup", isOn: Binding(
                    get: { model.settingsStore.settings.openOnStartup },
                    set: { model.setOpenOnStartup($0) }
                ))
                toggleRow("Show in dock", isOn: Binding(
                    get: { model.settingsStore.settings.showInDock },
                    set: { model.setShowInDock($0) }
                ))
                toggleRow("Show in menu bar", isOn: Binding(
                    get: { model.settingsStore.settings.showInMenuBar },
                    set: { model.setShowInMenuBar($0) }
                ))
            }

            ForEach(shortcutSections) { section in
                self.section(section.title) {
                    ForEach(section.rows) { row in
                        ShortcutCaptureRow(
                            title: row.title,
                            value: row.value(model.settingsStore.settings.shortcuts),
                            captureKey: row.id,
                            activeCapture: $captureKey,
                            theme: theme
                        ) { next in
                            model.updateShortcut { shortcuts in
                                row.set(&shortcuts, next)
                            }
                        }
                    }
                }
            }
        }
    }

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(theme.textMuted)
                .padding(.top, 8)

            content()
        }
    }

    private func toggleRow(_ label: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(theme.textPrimary)

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(minHeight: 40)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.border)
                .frame(height: 1)
        }
    }
}

@MainActor
private struct ShortcutSectionViewModel: Identifiable {
    let id: String
    let title: String
    let rows: [ShortcutRowViewModel]
}

@MainActor
private struct ShortcutRowViewModel: Identifiable {
    let id: ShortcutCaptureKey
    let title: String
    let value: (ShortcutMap) -> String
    let set: (inout ShortcutMap, String) -> Void
}

private struct ShortcutCaptureRow: View {
    let title: String
    let value: String
    let captureKey: ShortcutCaptureKey
    @Binding var activeCapture: ShortcutCaptureKey?
    let theme: AppTheme
    let onSave: (String) -> Void

    @State private var monitor: Any?

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(theme.textPrimary)

            Spacer()

            Button(activeCapture == captureKey ? "Press keys" : ShortcutFormatter.display(value)) {
                activeCapture = captureKey
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .regular, design: .monospaced))
            .foregroundStyle(activeCapture == captureKey ? theme.textPrimary : theme.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(activeCapture == captureKey ? theme.surfaceHover : theme.background)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(activeCapture == captureKey ? theme.accent : theme.border, lineWidth: 1)
            )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(minHeight: 40)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.border)
                .frame(height: 1)
        }
        .onChange(of: activeCapture == captureKey) { _, isActive in
            isActive ? installMonitor() : removeMonitor()
        }
        .onDisappear {
            removeMonitor()
        }
    }

    private func installMonitor() {
        removeMonitor()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard activeCapture == captureKey else {
                return event
            }

            if event.keyCode == 53 {
                activeCapture = nil
                return nil
            }

            if event.keyCode == 51 || event.keyCode == 117 {
                onSave("")
                activeCapture = nil
                return nil
            }

            let next = EventShortcutFormatter.format(event)
            guard next.isEmpty == false else {
                return nil
            }

            onSave(next)
            activeCapture = nil
            return nil
        }
    }

    private func removeMonitor() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}

private enum ShortcutCaptureKey: String, Hashable {
    case toggleWindow
    case openSettings
    case newTab
    case deleteTab
    case moveTabLeft
    case moveTabRight
    case createItemBelow
    case createItemAbove
    case editItem
    case deleteItem
    case checkItem
    case openItemLink
    case sortByTag
    case enterMoveMode
    case undo
}

@MainActor
private let shortcutSections: [ShortcutSectionViewModel] = [
    .init(
        id: "window",
        title: "Window",
        rows: [
            .init(id: .toggleWindow, title: "Toggle window", value: { $0.toggleWindow }, set: { $0.toggleWindow = $1 }),
            .init(id: .openSettings, title: "Open settings", value: { $0.openSettings }, set: { $0.openSettings = $1 }),
        ]
    ),
    .init(
        id: "tabs",
        title: "Tabs",
        rows: [
            .init(id: .newTab, title: "New tab", value: { $0.newTab }, set: { $0.newTab = $1 }),
            .init(id: .deleteTab, title: "Delete list", value: { $0.deleteTab }, set: { $0.deleteTab = $1 }),
            .init(id: .moveTabLeft, title: "Move tab left", value: { $0.moveTabLeft }, set: { $0.moveTabLeft = $1 }),
            .init(id: .moveTabRight, title: "Move tab right", value: { $0.moveTabRight }, set: { $0.moveTabRight = $1 }),
        ]
    ),
    .init(
        id: "items",
        title: "Item editing",
        rows: [
            .init(id: .createItemBelow, title: "New item below", value: { $0.createItemBelow }, set: { $0.createItemBelow = $1 }),
            .init(id: .createItemAbove, title: "New item above", value: { $0.createItemAbove }, set: { $0.createItemAbove = $1 }),
            .init(id: .editItem, title: "Edit focused item", value: { $0.editItem }, set: { $0.editItem = $1 }),
            .init(id: .deleteItem, title: "Delete focused item", value: { $0.deleteItem }, set: { $0.deleteItem = $1 }),
            .init(id: .checkItem, title: "Check item", value: { $0.checkItem }, set: { $0.checkItem = $1 }),
            .init(id: .openItemLink, title: "Open item link", value: { $0.openItemLink }, set: { $0.openItemLink = $1 }),
            .init(id: .sortByTag, title: "Toggle tag sort", value: { $0.sortByTag }, set: { $0.sortByTag = $1 }),
        ]
    ),
    .init(
        id: "movement",
        title: "Move mode",
        rows: [
            .init(id: .enterMoveMode, title: "Enter move mode", value: { $0.enterMoveMode }, set: { $0.enterMoveMode = $1 }),
            .init(id: .undo, title: "Undo", value: { $0.undo }, set: { $0.undo = $1 }),
        ]
    ),
]
