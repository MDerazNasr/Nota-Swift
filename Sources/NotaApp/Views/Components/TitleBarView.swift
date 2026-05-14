import NotaCore
import SwiftUI

struct TitleBarView: View {
    @Environment(NotaApplicationModel.self) private var model

    let theme: AppTheme

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                dotButton(color: Color(css: "#ef4444")) {
                    model.windowCoordinator.hideWindow()
                }

                dotButton(color: Color(css: "#f59e0b")) {
                    model.windowCoordinator.minimizeWindow()
                }

                Circle()
                    .fill(theme.border)
                    .frame(width: 8, height: 8)
            }
            .frame(width: 64, alignment: .leading)
            .padding(.leading, 12)

            Text("nota")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(theme.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                iconButton(
                    systemName: "tag",
                    active: tagSortActive,
                    enabled: canSortByTag
                ) {
                    model.notesStore.sortActiveTabByTag()
                }

                iconButton(systemName: "gearshape", active: model.settingsOpen, enabled: true) {
                    model.toggleSettings()
                }
            }
            .frame(width: 64, alignment: .trailing)
            .padding(.trailing, 4)
        }
        .frame(height: 36)
        .background(theme.background)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.border)
                .frame(height: 1)
        }
    }

    private var tagSortActive: Bool {
        model.notesStore.tagSortOriginalItemIds[model.notesStore.activeTabId] != nil
    }

    private var canSortByTag: Bool {
        tagSortActive || (model.notesStore.activeTab?.items.contains { $0.tags.isEmpty == false } ?? false)
    }

    private func dotButton(color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
        }
        .buttonStyle(.plain)
    }

    private func iconButton(
        systemName: String,
        active: Bool,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(active ? theme.textPrimary : theme.textSecondary)
                .frame(width: 28, height: 28)
                .background(active ? theme.accentMuted : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(enabled == false)
        .opacity(enabled ? 1 : 0.45)
    }
}
