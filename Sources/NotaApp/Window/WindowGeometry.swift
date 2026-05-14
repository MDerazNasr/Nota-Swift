import CoreGraphics

enum WindowGeometry {
    static let defaultWidth: CGFloat = 380
    static let defaultHeight: CGFloat = 560
    static let legacyDefaultHeight: CGFloat = 500
    static let minWidth: CGFloat = 300
    static let minHeight: CGFloat = 400
    static let maxWidth: CGFloat = 800
    static let maxHeight: CGFloat = 900
    static let edgeOffset: CGFloat = 16

    static func clampedSize(_ size: CGSize) -> CGSize {
        CGSize(
            width: size.width.clamped(to: minWidth...maxWidth),
            height: size.height.clamped(to: minHeight...maxHeight)
        )
    }

    static func restoredSize(_ size: CGSize?) -> CGSize {
        guard let size else {
            return CGSize(width: defaultWidth, height: defaultHeight)
        }

        if size.width == defaultWidth, size.height == legacyDefaultHeight {
            return CGSize(width: defaultWidth, height: defaultHeight)
        }

        return clampedSize(size)
    }

    static func clampedOrigin(origin: CGPoint, size: CGSize, visibleFrames: [CGRect]) -> CGPoint? {
        guard let frame = visibleFrames.first(where: { $0.contains(origin) }) else {
            return nil
        }

        let clampedSize = clampedSize(size)
        let maxX = max(frame.minX, frame.maxX - clampedSize.width)
        let maxY = max(frame.minY, frame.maxY - clampedSize.height)
        return CGPoint(
            x: origin.x.clamped(to: frame.minX...maxX),
            y: origin.y.clamped(to: frame.minY...maxY)
        )
    }

    static func topRightOrigin(size: CGSize, visibleFrame: CGRect) -> CGPoint {
        CGPoint(
            x: visibleFrame.maxX - size.width - edgeOffset,
            y: visibleFrame.maxY - size.height - edgeOffset
        )
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
