import AppKit

@MainActor
final class MenuBarController {
    private var statusItem: NSStatusItem?
    private var toggle: (() -> Void)?

    func setVisible(_ visible: Bool, toggle: @escaping () -> Void) {
        self.toggle = toggle

        if visible == false {
            if let statusItem {
                NSStatusBar.system.removeStatusItem(statusItem)
                self.statusItem = nil
            }
            return
        }

        if statusItem == nil {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            item.button?.title = "nota"
            item.button?.target = self
            item.button?.action = #selector(handleToggle)
            statusItem = item
        }
    }

    @objc
    private func handleToggle() {
        toggle?()
    }
}
