import Carbon
import Foundation

enum ShortcutParser {
    static func parseCarbonShortcut(_ shortcut: String) -> (keyCode: UInt32, modifiers: UInt32)? {
        let parts = shortcut.split(separator: "+").map(String.init)
        guard let keyPart = parts.last,
              let keyCode = ShortcutKeyName.carbonKeyCode(for: keyPart) else {
            return nil
        }

        var modifiers: UInt32 = 0

        for part in parts.dropLast() {
            switch part {
            case "Alt":
                modifiers |= UInt32(optionKey)
            case "Shift":
                modifiers |= UInt32(shiftKey)
            case "CommandOrControl":
                modifiers |= UInt32(cmdKey)
            default:
                break
            }
        }

        return (keyCode, modifiers)
    }
}
