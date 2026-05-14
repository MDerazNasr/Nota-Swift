import AppKit
import Testing
@testable import NotaApp

struct ShortcutKeyNameTests {
    @Test
    func normalizesLetterDigitAndSpecialKeys() {
        #expect(
            ShortcutKeyName.normalizedKey(
                characters: "n",
                charactersIgnoringModifiers: "n",
                keyCode: 45,
                modifierFlags: []
            ) == "N"
        )

        #expect(
            ShortcutKeyName.normalizedKey(
                characters: "n",
                charactersIgnoringModifiers: "n",
                keyCode: 45,
                modifierFlags: [.option]
            ) == "KeyN"
        )

        #expect(
            ShortcutKeyName.normalizedKey(
                characters: "<",
                charactersIgnoringModifiers: ",",
                keyCode: 43,
                modifierFlags: [.shift]
            ) == "<"
        )

        #expect(
            ShortcutKeyName.normalizedKey(
                characters: nil,
                charactersIgnoringModifiers: nil,
                keyCode: 51,
                modifierFlags: []
            ) == "Delete"
        )
    }
}
