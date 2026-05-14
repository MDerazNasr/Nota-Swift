import CoreGraphics
import Testing
@testable import NotaApp

struct WindowGeometryTests {
    @Test
    func restoredLegacyDefaultHeightMigrates() {
        let restored = WindowGeometry.restoredSize(CGSize(width: 380, height: 500))

        #expect(restored.width == 380)
        #expect(restored.height == 560)
    }

    @Test
    func clampedSizeRespectsBounds() {
        let clamped = WindowGeometry.clampedSize(CGSize(width: 1000, height: 100))

        #expect(clamped.width == 800)
        #expect(clamped.height == 400)
    }

    @Test
    func clampedOriginRejectsOffscreenAndClampsVisibleFrame() {
        let frame = CGRect(x: 100, y: 100, width: 900, height: 700)
        let size = CGSize(width: 380, height: 560)

        let offscreen = WindowGeometry.clampedOrigin(
            origin: CGPoint(x: 10, y: 10),
            size: size,
            visibleFrames: [frame]
        )
        let clamped = WindowGeometry.clampedOrigin(
            origin: CGPoint(x: 900, y: 700),
            size: size,
            visibleFrames: [frame]
        )

        #expect(offscreen == nil)
        #expect(clamped == CGPoint(x: 620, y: 240))
    }
}
