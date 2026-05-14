import NotaCore
import SwiftUI

struct ItemListView: View {
    @Environment(NotaApplicationModel.self) private var model
    @State private var viewportHeight: CGFloat = 0

    let theme: AppTheme

    var body: some View {
        GeometryReader { geometry in
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
                                .background(
                                    GeometryReader { rowGeometry in
                                        Color.clear.preference(
                                            key: VisibleItemFrameKey.self,
                                            value: [VisibleItemFrame(id: item.id, frame: rowGeometry.frame(in: .named("item-list-scroll")))]
                                        )
                                    }
                                )
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
                .coordinateSpace(name: "item-list-scroll")
                .background(theme.background)
                .onChange(of: model.notesStore.cursorIndex) { _, _ in
                    scrollFocusedItem(with: proxy)
                }
                .onAppear {
                    viewportHeight = geometry.size.height
                    scrollFocusedItem(with: proxy)
                }
                .onChange(of: geometry.size.height) { _, nextHeight in
                    viewportHeight = nextHeight
                }
                .onPreferenceChange(VisibleItemFrameKey.self) { frames in
                    updateVisibleItems(frames)
                }
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

    private func updateVisibleItems(_ frames: [VisibleItemFrame]) {
        let visibleIds = frames
            .filter { $0.frame.maxY > 0 && $0.frame.minY < viewportHeight }
            .sorted { $0.frame.minY < $1.frame.minY }
            .map(\.id)

        if model.visibleItemIds != visibleIds {
            model.visibleItemIds = visibleIds
        }
    }
}

private struct VisibleItemFrame: Equatable {
    let id: String
    let frame: CGRect
}

private struct VisibleItemFrameKey: PreferenceKey {
    static let defaultValue: [VisibleItemFrame] = []

    static func reduce(value: inout [VisibleItemFrame], nextValue: () -> [VisibleItemFrame]) {
        value.append(contentsOf: nextValue())
    }
}
