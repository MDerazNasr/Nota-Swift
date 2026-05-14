import NotaCore
import SwiftUI
import UniformTypeIdentifiers

struct ItemRowView: View {
    @Environment(NotaApplicationModel.self) private var model
    @StateObject private var editorBridge = RichTextEditorView.Bridge()
    @State private var editorMode: ItemEditorMode = .insert
    @State private var slashState: RichTextEditorView.SlashState?
    @State private var slashSelectionIndex = 0
    @State private var showLinkPopup = false
    @State private var focusedTagIndex: Int?

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

                ZStack(alignment: .topLeading) {
                    RichTextEditorView(
                        bridge: editorBridge,
                        richText: item.richText,
                        editable: editable,
                        fontName: model.settingsStore.settings.font.rawValue,
                        fontSize: CGFloat(model.settingsStore.settings.fontSize),
                        mode: $editorMode,
                        onChange: { nextRichText in
                            model.notesStore.updateItemRichText(tabId: tabId, itemId: item.id, richText: nextRichText)
                        },
                        onFocus: {
                            focusItem(editing: true)
                        },
                        onExitEditor: {
                            model.notesStore.setMode(.nav)
                        },
                        onCheckItem: {
                            model.notesStore.checkItem(tabId: tabId, itemId: item.id)
                        },
                        onSlashStateChange: { nextState in
                            slashState = nextState
                            slashSelectionIndex = 0
                        },
                        onEditorEvent: { event, textView, mode in
                            handleEditorEvent(event, textView: textView, mode: mode)
                        }
                    )
                    .frame(maxWidth: .infinity, minHeight: 16, alignment: .leading)

                    if editable,
                       editorMode != .insert,
                       let cursorRect = editorBridge.cursorRect {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(.white)
                            .frame(
                                width: editorMode == .visual || editorMode == .visualLine ? 2 : 9,
                                height: max(16, cursorRect.height)
                            )
                            .blendMode(.difference)
                            .offset(x: max(cursorRect.minX - 3, 0), y: cursorRect.minY)
                            .allowsHitTesting(false)
                    }
                }
            }

            if item.tags.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(item.tags) { tag in
                            HStack(spacing: 3) {
                                Text(tag.name)
                                Button {
                                    model.notesStore.removeItemTag(tabId: tabId, itemId: item.id, tagName: tag.name)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 8, weight: .bold))
                                }
                                .buttonStyle(.plain)
                            }
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .foregroundStyle(Color(css: tag.color))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(focusedTagIndex == index(for: tag.id) ? Color(css: tag.color).opacity(0.16) : .clear)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        focusedTagIndex == index(for: tag.id) ? theme.textPrimary : Color(css: tag.color),
                                        lineWidth: 1
                                    )
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
        .overlay(alignment: .bottomLeading) {
            if let slashState {
                let items = SlashCommandUtilities.buildItems(
                    query: slashState.query,
                    availableTags: TagUtilities.collectActiveTags(from: model.notesStore.tabs),
                    itemTags: item.tags
                )

                if items.isEmpty == false {
                    SlashMenuView(
                        items: items,
                        selectedIndex: slashSelectionIndex,
                        theme: theme
                    ) { selectedItem in
                        selectSlashItem(selectedItem, slashState: slashState)
                    }
                    .offset(x: 28, y: 40)
                }
            }
        }
        .overlay(alignment: .bottomLeading) {
            if showLinkPopup {
                LinkPopupView(theme: theme) { label, url in
                    editorBridge.insertLink(label: label, url: url)
                    showLinkPopup = false
                    editorMode = .normal
                    editorBridge.focus()
                } onCancel: {
                    showLinkPopup = false
                    editorMode = .normal
                    editorBridge.focus()
                }
                .offset(x: 28, y: 40)
            }
        }
        .opacity(item.state == .done ? theme.doneOpacity : 1)
        .contentShape(Rectangle())
        .onTapGesture {
            focusItem(editing: true)
        }
        .onDrag {
            let draggedIds = model.notesStore.selectedItemIds.contains(item.id) ? model.notesStore.selectedItemIds : [item.id]
            model.notesStore.setSelectedItemIds(draggedIds)
            model.notesStore.startItemDrag(draggedIds)
            return NSItemProvider(object: NSString(string: item.id))
        }
        .onChange(of: editable) { _, nextEditable in
            guard nextEditable else {
                focusedTagIndex = nil
                slashState = nil
                showLinkPopup = false
                return
            }

            editorMode = .insert
            DispatchQueue.main.async {
                editorBridge.focus()
            }
        }
        .onDrop(
            of: [UTType.text],
            delegate: ItemRowDropDelegate(model: model, tabId: tabId, itemId: item.id)
        )
    }

    private var editable: Bool {
        focused && model.notesStore.mode == .edit
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

    private func focusItem(editing: Bool) {
        guard let activeTab = model.notesStore.activeTab,
              let index = activeTab.items.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        model.notesStore.setCursorIndex(index)
        model.notesStore.setMode(editing ? .edit : .nav)
    }

    private func index(for tagId: String) -> Int? {
        item.tags.firstIndex { $0.id == tagId }
    }

    private func handleEditorEvent(_ event: NSEvent, textView: NotaTextView, mode: ItemEditorMode) -> Bool {
        if let slashState {
            return handleSlashEvent(event, slashState: slashState)
        }

        if let focusedTagIndex {
            return handleTagFocusEvent(event, focusedTagIndex: focusedTagIndex)
        }

        guard mode == .normal else {
            return false
        }

        if event.keyCode == 124,
           textView.selectedRange().location >= textView.string.count,
           item.tags.isEmpty == false {
            self.focusedTagIndex = 0
            return true
        }

        return false
    }

    private func handleSlashEvent(_ event: NSEvent, slashState: RichTextEditorView.SlashState) -> Bool {
        let items = SlashCommandUtilities.buildItems(
            query: slashState.query,
            availableTags: TagUtilities.collectActiveTags(from: model.notesStore.tabs),
            itemTags: item.tags
        )
        guard items.isEmpty == false else {
            return false
        }

        switch event.keyCode {
        case 53:
            editorBridge.replace(range: slashState.range, with: "")
            self.slashState = nil
            return true
        case 36, 76:
            let index = min(max(slashSelectionIndex, 0), items.count - 1)
            selectSlashItem(items[index], slashState: slashState)
            return true
        case 125:
            slashSelectionIndex = min(slashSelectionIndex + 1, items.count - 1)
            return true
        case 126:
            slashSelectionIndex = max(slashSelectionIndex - 1, 0)
            return true
        default:
            return false
        }
    }

    private func selectSlashItem(_ selectedItem: SlashMenuItem, slashState: RichTextEditorView.SlashState?) {
        guard let slashState else {
            return
        }

        editorBridge.replace(range: slashState.range, with: "")
        self.slashState = nil

        switch selectedItem {
        case .command:
            showLinkPopup = true
        case let .tag(_, tag, _, _):
            model.notesStore.addItemTag(tabId: tabId, itemId: item.id, tagName: tag.name)
        case let .createTag(_, name, _, _):
            model.notesStore.addItemTag(tabId: tabId, itemId: item.id, tagName: name)
        }
    }

    private func handleTagFocusEvent(_ event: NSEvent, focusedTagIndex: Int) -> Bool {
        switch event.keyCode {
        case 123:
            if focusedTagIndex == 0 {
                self.focusedTagIndex = nil
            } else {
                self.focusedTagIndex = focusedTagIndex - 1
            }
            return true
        case 124:
            self.focusedTagIndex = min(focusedTagIndex + 1, item.tags.count - 1)
            return true
        case 51, 117:
            guard item.tags.indices.contains(focusedTagIndex) else {
                return true
            }

            let tag = item.tags[focusedTagIndex]
            model.notesStore.removeItemTag(tabId: tabId, itemId: item.id, tagName: tag.name)
            let nextCount = item.tags.count - 1
            if nextCount <= 0 {
                self.focusedTagIndex = nil
            } else {
                self.focusedTagIndex = min(focusedTagIndex, nextCount - 1)
            }
            return true
        case 53:
            self.focusedTagIndex = nil
            return true
        default:
            return false
        }
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
