import AppKit
import SwiftUI

struct WindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowDragAreaView {
        WindowDragAreaView()
    }

    func updateNSView(_ nsView: WindowDragAreaView, context: Context) {
    }
}

final class WindowDragAreaView: NSView {
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}
