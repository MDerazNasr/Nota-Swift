import Foundation

public enum ShortcutFormatter {
    public static func display(_ shortcut: String) -> String {
        guard shortcut.isEmpty == false else {
            return "Disabled"
        }

        let tokens = shortcut
            .split(separator: "+")
            .map(String.init)

        let modifiers = tokens.dropLast().compactMap(displayModifier)
        let key = displayKey(tokens.last ?? "")
        return modifiers.joined() + key
    }

    private static func displayModifier(_ token: String) -> String? {
        switch token {
        case "CommandOrControl":
            return "\u{2318}"
        case "Alt":
            return "\u{2325}"
        case "Shift":
            return "\u{21E7}"
        default:
            return nil
        }
    }

    private static func displayKey(_ token: String) -> String {
        switch token {
        case "Space":
            return "Space"
        case "Delete":
            return "\u{232B}"
        case "Enter":
            return "\u{21A9}"
        case "Tab":
            return "\u{21E5}"
        case "Escape":
            return "\u{238B}"
        case let key where key.hasPrefix("Key") && key.count == 4:
            return String(key.suffix(1))
        default:
            return token.uppercased()
        }
    }
}
