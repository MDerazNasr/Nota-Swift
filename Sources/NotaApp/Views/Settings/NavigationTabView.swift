import NotaCore
import SwiftUI

struct NavigationTabView: View {
    @Environment(NotaApplicationModel.self) private var model

    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            section("Behavior") {
                toggleRow("Open on startup", isOn: Binding(
                    get: { model.settingsStore.settings.openOnStartup },
                    set: { model.settingsStore.setOpenOnStartup($0) }
                ))
                toggleRow("Show in dock", isOn: Binding(
                    get: { model.settingsStore.settings.showInDock },
                    set: { model.settingsStore.setShowInDock($0) }
                ))
                toggleRow("Show in menu bar", isOn: Binding(
                    get: { model.settingsStore.settings.showInMenuBar },
                    set: { model.settingsStore.setShowInMenuBar($0) }
                ))
            }

            ForEach(shortcutSections) { section in
                self.section(section.title) {
                    ForEach(section.rows) { row in
                        shortcutRow(row.title, shortcut: row.value(model.settingsStore.settings.shortcuts))
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

    private func shortcutRow(_ label: String, shortcut: String) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(theme.textPrimary)

            Spacer()

            Text(ShortcutFormatter.display(shortcut))
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(theme.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(theme.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.border, lineWidth: 1)
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
    let id: String
    let title: String
    let value: (ShortcutMap) -> String
}

@MainActor
private let shortcutSections: [ShortcutSectionViewModel] = [
    .init(
        id: "window",
        title: "Window",
        rows: [
            .init(id: "toggleWindow", title: "Toggle window", value: { $0.toggleWindow }),
            .init(id: "openSettings", title: "Open settings", value: { $0.openSettings }),
        ]
    ),
    .init(
        id: "tabs",
        title: "Tabs",
        rows: [
            .init(id: "newTab", title: "New tab", value: { $0.newTab }),
            .init(id: "deleteTab", title: "Delete list", value: { $0.deleteTab }),
            .init(id: "moveTabLeft", title: "Move tab left", value: { $0.moveTabLeft }),
            .init(id: "moveTabRight", title: "Move tab right", value: { $0.moveTabRight }),
        ]
    ),
    .init(
        id: "items",
        title: "Item editing",
        rows: [
            .init(id: "createItemBelow", title: "New item below", value: { $0.createItemBelow }),
            .init(id: "createItemAbove", title: "New item above", value: { $0.createItemAbove }),
            .init(id: "editItem", title: "Edit focused item", value: { $0.editItem }),
            .init(id: "deleteItem", title: "Delete focused item", value: { $0.deleteItem }),
            .init(id: "checkItem", title: "Check item", value: { $0.checkItem }),
            .init(id: "openItemLink", title: "Open item link", value: { $0.openItemLink }),
            .init(id: "sortByTag", title: "Toggle tag sort", value: { $0.sortByTag }),
        ]
    ),
    .init(
        id: "movement",
        title: "Move mode",
        rows: [
            .init(id: "enterMoveMode", title: "Enter move mode", value: { $0.enterMoveMode }),
            .init(id: "undo", title: "Undo", value: { $0.undo }),
        ]
    ),
]
