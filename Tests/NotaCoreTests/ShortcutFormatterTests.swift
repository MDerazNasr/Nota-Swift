import Foundation
import Testing
@testable import NotaCore

struct ShortcutFormatterTests {
    @Test
    func formatsMacDisplayStrings() {
        #expect(ShortcutFormatter.display("Alt+Shift+KeyN") == "\u{2325}\u{21E7}N")
        #expect(ShortcutFormatter.display("CommandOrControl+,") == "\u{2318},")
        #expect(ShortcutFormatter.display("Delete") == "\u{232B}")
        #expect(ShortcutFormatter.display("Space") == "Space")
    }

    @Test
    func emptyShortcutDisplaysDisabled() {
        #expect(ShortcutFormatter.display("") == "Disabled")
    }
}
