import AppKit

enum EventShortcutFormatter {
    static func format(_ event: NSEvent) -> String {
        guard let characters = event.charactersIgnoringModifiers, characters.isEmpty == false else {
            return ""
        }

        if ["⌥", "⌘", "⌃", "⇧"].contains(characters) {
            return ""
        }

        var parts: [String] = []

        if event.modifierFlags.contains(.command) || event.modifierFlags.contains(.control) {
            parts.append("CommandOrControl")
        }

        if event.modifierFlags.contains(.option) {
            parts.append("Alt")
        }

        if event.modifierFlags.contains(.shift) {
            parts.append("Shift")
        }

        let key = ShortcutKeyName.normalizedKey(
            characters: event.characters,
            charactersIgnoringModifiers: event.charactersIgnoringModifiers,
            keyCode: event.keyCode,
            modifierFlags: event.modifierFlags
        )
        guard key.isEmpty == false else {
            return ""
        }

        parts.append(key)
        return parts.joined(separator: "+")
    }
}
