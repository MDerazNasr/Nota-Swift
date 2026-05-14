import NotaCore
import SwiftUI

struct ItemListView: View {
    @Environment(NotaApplicationModel.self) private var model

    let theme: AppTheme

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    if let activeTab = model.notesStore.activeTab, activeTab.items.isEmpty == false {
                        ForEach(Array(activeTab.items.enumerated()), id: \.element.id) { index, item in
                            ItemRowView(
                                item: item,
                                tabId: activeTab.id,
                                focused: model.notesStore.cursorIndex == index,
                                selected: model.notesStore.selectedItemIds.contains(item.id),
                                dropTarget: dropTarget(for: item.id, tabId: activeTab.id),
                                theme: theme
                            )
                            .id(item.id)
                        }
                    } else {
                        Text("Press o to add an item")
                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            .foregroundStyle(theme.textMuted)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 24)
                    }

                    if activeTabIsAtLimit {
                        Text("limit reached")
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundStyle(Color(css: "#f87171"))
                            .padding(.top, 8)
                    }
                }
                .padding(8)
            }
            .background(theme.background)
            .onChange(of: model.notesStore.cursorIndex) { _, _ in
                scrollFocusedItem(with: proxy)
            }
            .onAppear {
                scrollFocusedItem(with: proxy)
            }
        }
    }

    private var activeTabIsAtLimit: Bool {
        (model.notesStore.activeTab?.items.count ?? 0) >= model.settingsStore.settings.itemLimit
    }

    private func dropTarget(for itemId: String, tabId: String) -> DropPosition? {
        guard let target = model.notesStore.itemDropTarget,
              target.tabId == tabId,
              target.itemId == itemId else {
            return nil
        }

        return target.position
    }

    private func scrollFocusedItem(with proxy: ScrollViewProxy) {
        guard let activeTab = model.notesStore.activeTab,
              activeTab.items.indices.contains(model.notesStore.cursorIndex) else {
            return
        }

        proxy.scrollTo(activeTab.items[model.notesStore.cursorIndex].id, anchor: .center)
    }
}
