import Foundation
import NotaCore

enum VisibleCursorPosition {
    case top
    case middle
    case bottom
}

struct NavCommandBuffer {
    private(set) var pendingDeleteTimestamp: TimeInterval?

    mutating func registerDelete(now: TimeInterval, threshold: TimeInterval = 0.5) -> Bool {
        defer { pendingDeleteTimestamp = now }

        guard let pendingDeleteTimestamp else {
            return false
        }

        if now - pendingDeleteTimestamp <= threshold {
            self.pendingDeleteTimestamp = nil
            return true
        }

        return false
    }

    mutating func clear() {
        pendingDeleteTimestamp = nil
    }
}

func visibleCursorIndex(
    orderedVisibleItemIds: [String],
    items: [Item],
    position: VisibleCursorPosition
) -> Int? {
    guard orderedVisibleItemIds.isEmpty == false else {
        return nil
    }

    let targetId: String
    switch position {
    case .top:
        targetId = orderedVisibleItemIds[0]
    case .middle:
        targetId = orderedVisibleItemIds[orderedVisibleItemIds.count / 2]
    case .bottom:
        targetId = orderedVisibleItemIds[orderedVisibleItemIds.count - 1]
    }

    return items.firstIndex { $0.id == targetId }
}
