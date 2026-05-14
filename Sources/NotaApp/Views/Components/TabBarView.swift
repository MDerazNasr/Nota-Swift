import NotaCore
import SwiftUI

struct TabBarView: View {
    @Environment(NotaApplicationModel.self) private var model

    let theme: AppTheme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(model.notesStore.tabs) { tab in
                    TabPillView(tab: tab, theme: theme)
                }

                Button {
                    model.notesStore.createTab()
                } label: {
                    Text("+")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(theme.textSecondary)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 32)
        .background(theme.background)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.border)
                .frame(height: 1)
        }
    }
}

private struct TabPillView: View {
    @Environment(NotaApplicationModel.self) private var model
    @FocusState private var titleFocused: Bool
    @State private var draftTitle = ""

    let tab: NotaCore.Tab
    let theme: AppTheme

    var body: some View {
        HStack(spacing: 6) {
            if model.notesStore.editingTabId == tab.id {
                TextField("", text: $draftTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(theme.textPrimary)
                    .focused($titleFocused)
                    .frame(width: 120)
                    .onAppear {
                        draftTitle = tab.title
                        titleFocused = true
                    }
                    .onSubmit {
                        commitTitle()
                    }
            } else {
                Button {
                    model.notesStore.setActiveTab(id: tab.id)
                } label: {
                    Text(tab.title)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(titleColor)
                        .lineLimit(1)
                        .frame(maxWidth: 120)
                }
                .buttonStyle(.plain)
                .simultaneousGesture(
                    TapGesture(count: 2).onEnded {
                        beginTitleEdit()
                    }
                )
                .contextMenu {
                    Button("Delete") {
                        model.notesStore.deleteTab(id: tab.id)
                    }
                }
            }

            Button {
                model.notesStore.deleteTab(id: tab.id)
            } label: {
                Text("x")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(theme.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 6)
        .frame(height: 32)
        .background(backgroundShape.fill(backgroundColor))
        .overlay(backgroundShape.stroke(outlineColor, lineWidth: outlineColor == .clear ? 0 : 1))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(model.notesStore.activeTabId == tab.id ? theme.accent : Color.clear)
                .frame(height: 2)
        }
    }

    private var titleColor: Color {
        if isMoving {
            return theme.accent
        }
        return model.notesStore.activeTabId == tab.id ? theme.textPrimary : theme.textSecondary
    }

    private var backgroundShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 8)
    }

    private var backgroundColor: Color {
        if isMoving {
            return theme.surfaceHover
        }
        if isKeyboardFocused {
            return theme.accentMuted
        }
        return .clear
    }

    private var outlineColor: Color {
        if isMoving || isKeyboardFocused {
            return theme.accent
        }
        return .clear
    }

    private var isKeyboardFocused: Bool {
        model.notesStore.activeTabId == tab.id && model.notesStore.mode == .tabs
    }

    private var isMoving: Bool {
        model.notesStore.activeTabId == tab.id && model.notesStore.mode == .tabMove
    }

    private func beginTitleEdit() {
        model.notesStore.setEditingTabId(tab.id)
        draftTitle = tab.title
    }

    private func commitTitle() {
        model.notesStore.updateTabTitle(id: tab.id, title: draftTitle)
    }
}
