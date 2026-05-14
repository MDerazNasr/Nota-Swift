import AppKit

enum ShortcutKeyName {
    static func normalizedKey(
        characters: String?,
        charactersIgnoringModifiers: String?,
        keyCode: UInt16,
        modifierFlags: NSEvent.ModifierFlags
    ) -> String {
        if let special = specialKeyName(for: keyCode) {
            return special
        }

        if modifierFlags.contains(.shift),
           let shifted = characters,
           ["<", ">", ".", ",", "/", "?", ":", ";"].contains(shifted) {
            return shifted
        }

        guard let base = charactersIgnoringModifiers, base.count == 1 else {
            return charactersIgnoringModifiers ?? characters ?? ""
        }

        let upper = base.uppercased()
        guard let first = upper.first else {
            return upper
        }

        if modifierFlags.contains(.option) || first.isNumber {
            return "Key\(first)"
        }

        if first.isLetter {
            return String(first)
        }

        return upper
    }

    static func carbonKeyCode(for key: String) -> UInt32? {
        switch key {
        case "KeyA": 0x00
        case "KeyS": 0x01
        case "KeyD": 0x02
        case "KeyF": 0x03
        case "KeyH": 0x04
        case "KeyG": 0x05
        case "KeyZ": 0x06
        case "KeyX": 0x07
        case "KeyC": 0x08
        case "KeyV": 0x09
        case "KeyB": 0x0B
        case "KeyQ": 0x0C
        case "KeyW": 0x0D
        case "KeyE": 0x0E
        case "KeyR": 0x0F
        case "KeyY": 0x10
        case "KeyT": 0x11
        case "Key1": 0x12
        case "Key2": 0x13
        case "Key3": 0x14
        case "Key4": 0x15
        case "Key6": 0x16
        case "Key5": 0x17
        case "Equal": 0x18
        case "Key9": 0x19
        case "Key7": 0x1A
        case "Minus": 0x1B
        case "Key8": 0x1C
        case "Key0": 0x1D
        case "KeyO": 0x1F
        case "KeyU": 0x20
        case "KeyI": 0x22
        case "KeyP": 0x23
        case "KeyL": 0x25
        case "KeyJ": 0x26
        case "KeyK": 0x28
        case "Semicolon", ":": 0x29
        case "Comma", ",", "<": 0x2B
        case "Slash", "/", "?": 0x2C
        case "KeyN": 0x2D
        case "KeyM": 0x2E
        case "Period", ".", ">": 0x2F
        case "Space": 0x31
        case "Tab": 0x30
        case "Enter": 0x24
        case "Delete": 0x33
        default: nil
        }
    }

    private static func specialKeyName(for keyCode: UInt16) -> String? {
        switch keyCode {
        case 36, 76:
            return "Enter"
        case 48:
            return "Tab"
        case 49:
            return "Space"
        case 51, 117:
            return "Delete"
        case 53:
            return "Escape"
        case 123:
            return "ArrowLeft"
        case 124:
            return "ArrowRight"
        case 125:
            return "ArrowDown"
        case 126:
            return "ArrowUp"
        default:
            return nil
        }
    }
}
