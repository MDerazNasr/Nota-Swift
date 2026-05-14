import AppKit
import NotaCore

@MainActor
final class WindowCoordinator: NSObject, NSWindowDelegate {
    private weak var window: NSWindow?
    private weak var settingsStore: SettingsStore?

    func configure(window: NSWindow, settingsStore: SettingsStore) {
        guard self.window !== window else {
            return
        }

        self.window = window
        self.settingsStore = settingsStore
        window.delegate = self
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = false
        window.styleMask.insert(.fullSizeContentView)
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.minSize = CGSize(width: WindowGeometry.minWidth, height: WindowGeometry.minHeight)
        window.maxSize = CGSize(width: WindowGeometry.maxWidth, height: WindowGeometry.maxHeight)
        applySavedGeometry(from: settingsStore.settings)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applySavedGeometry(from settings: Settings) {
        guard let window else {
            return
        }

        let restoredSize = WindowGeometry.restoredSize(
            settings.windowSize.map { CGSize(width: $0.width, height: $0.height) }
        )
        window.setContentSize(restoredSize)

        if let position = settings.windowPosition,
           let origin = WindowGeometry.clampedOrigin(
               origin: CGPoint(x: position.x, y: position.y),
               size: restoredSize,
               visibleFrames: NSScreen.screens.map(\.visibleFrame)
           ) {
            window.setFrameOrigin(origin)
            return
        }

        if let screen = window.screen ?? NSScreen.main {
            window.setFrameOrigin(
                WindowGeometry.topRightOrigin(size: restoredSize, visibleFrame: screen.visibleFrame)
            )
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }

    func windowDidMove(_ notification: Notification) {
        saveGeometry()
    }

    func windowDidResize(_ notification: Notification) {
        saveGeometry()
    }

    private func saveGeometry() {
        guard let window, let settingsStore else {
            return
        }

        let size = WindowGeometry.clampedSize(window.frame.size)
        let origin = WindowGeometry.clampedOrigin(
            origin: window.frame.origin,
            size: size,
            visibleFrames: NSScreen.screens.map(\.visibleFrame)
        ) ?? window.frame.origin
        settingsStore.setWindowSize(WindowSize(width: size.width, height: size.height))
        settingsStore.setWindowPosition(WindowPosition(x: origin.x, y: origin.y))
    }
}
