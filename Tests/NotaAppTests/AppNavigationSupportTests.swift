import NotaCore
import Testing
@testable import NotaApp

struct AppNavigationSupportTests {
    @Test
    func deleteCommandRequiresDoublePressWithinThreshold() {
        var buffer = NavCommandBuffer()

        #expect(buffer.registerDelete(now: 10) == false)
        #expect(buffer.registerDelete(now: 10.4) == true)
        #expect(buffer.registerDelete(now: 11.2) == false)
    }

    @Test
    func visibleCursorSelectionTargetsTopMiddleAndBottomVisibleItems() {
        let items = [
            Item(id: "a", richText: .empty, state: .active, tags: [], createdAt: 0),
            Item(id: "b", richText: .empty, state: .active, tags: [], createdAt: 0),
            Item(id: "c", richText: .empty, state: .active, tags: [], createdAt: 0),
            Item(id: "d", richText: .empty, state: .active, tags: [], createdAt: 0),
        ]

        #expect(visibleCursorIndex(orderedVisibleItemIds: ["b", "c", "d"], items: items, position: .top) == 1)
        #expect(visibleCursorIndex(orderedVisibleItemIds: ["b", "c", "d"], items: items, position: .middle) == 2)
        #expect(visibleCursorIndex(orderedVisibleItemIds: ["b", "c", "d"], items: items, position: .bottom) == 3)
    }
}
