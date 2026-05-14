import NotaCore
import SwiftUI
import UniformTypeIdentifiers

struct ItemRowView: View {
    @Environment(NotaApplicationModel.self) private var model

    let item: Item
    let tabId: String
    let focused: Bool
    let selected: Bool
    let dropTarget: DropPosition?
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(theme.textMuted)
                    .frame(width: 16, height: 18, alignment: .topLeading)

                Button {
                    model.notesStore.toggleItemSelection(item.id)
                } label: {
                    Circle()
                        .strokeBorder(selected ? theme.accent : theme.textMuted, lineWidth: 1)
                        .background(Circle().fill(selected ? theme.accent : Color.clear))
                        .frame(width: 12, height: 12)
                        .padding(.top, 2)
                }
                .buttonStyle(.plain)
                .frame(width: 24, alignment: .leading)

                Text(item.richText.text.isEmpty ? " " : item.richText.text)
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundStyle(theme.textPrimary)
                    .lineSpacing(4)
                    .strikethrough(item.state == .done, color: theme.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 16, alignment: .leading)
                    .textSelection(.enabled)
            }

            if item.tags.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(item.tags) { tag in
                            Text(tag.name)
                                .font(.system(size: 10, weight: .regular, design: .monospaced))
                                .foregroundStyle(Color(css: tag.color))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .overlay(
                                    Capsule()
                                        .stroke(Color(css: tag.color), lineWidth: 1)
                                )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.leading, 24)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: CGFloat(model.settingsStore.settings.borderRadius)))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(focused ? theme.accent : Color.clear)
                .frame(width: 2)
        }
        .overlay(alignment: .topLeading) {
            if dropTarget == .before {
                Rectangle()
                    .fill(theme.accent)
                    .frame(height: 1)
            }
        }
        .overlay(alignment: .bottomLeading) {
            if dropTarget == .after {
                Rectangle()
                    .fill(theme.accent)
                    .frame(height: 1)
            }
        }
        .opacity(item.state == .done ? theme.doneOpacity : 1)
        .contentShape(Rectangle())
        .onTapGesture {
            focusItem()
        }
        .onDrag {
            let draggedIds = model.notesStore.selectedItemIds.contains(item.id) ? model.notesStore.selectedItemIds : [item.id]
            model.notesStore.setSelectedItemIds(draggedIds)
            model.notesStore.startItemDrag(draggedIds)
            return NSItemProvider(object: NSString(string: item.id))
        }
        .onDrop(
            of: [UTType.text],
            delegate: ItemRowDropDelegate(model: model, tabId: tabId, itemId: item.id)
        )
    }

    private var rowBackground: Color {
        if focused {
            return theme.accentMuted
        }
        if selected {
            return theme.surfaceHover
        }
        return .clear
    }

    private func focusItem() {
        guard let activeTab = model.notesStore.activeTab,
              let index = activeTab.items.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        model.notesStore.setCursorIndex(index)
        model.notesStore.setMode(.nav)
    }
}

private struct ItemRowDropDelegate: DropDelegate {
    let model: NotaApplicationModel
    let tabId: String
    let itemId: String

    func validateDrop(info: DropInfo) -> Bool {
        model.notesStore.draggingItemIds.isEmpty == false
    }

    func dropEntered(info: DropInfo) {
        model.notesStore.setDropTargetTabId(nil)
        model.notesStore.setItemDropTarget(
            ItemDropTarget(tabId: tabId, itemId: itemId, position: position(for: info))
        )
    }

    func dropExited(info: DropInfo) {
        model.notesStore.setItemDropTarget(nil)
    }

    func performDrop(info: DropInfo) -> Bool {
        model.notesStore.finishItemDrag(
            at: ItemDropTarget(tabId: tabId, itemId: itemId, position: position(for: info))
        )
        return true
    }

    private func position(for info: DropInfo) -> DropPosition {
        info.location.y < 16 ? .before : .after
    }
}
