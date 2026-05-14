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
