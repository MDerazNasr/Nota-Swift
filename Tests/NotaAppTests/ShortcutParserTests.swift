import Testing
@testable import NotaApp

struct ShortcutParserTests {
    @Test
    func parsesCarbonShortcutFromStoredFormat() {
        let parsed = ShortcutParser.parseCarbonShortcut("Alt+Shift+KeyN")

        #expect(parsed?.keyCode == 0x2D)
        #expect(parsed?.modifiers != nil)
    }

    @Test
    func returnsNilForUnknownShortcutKey() {
        #expect(ShortcutParser.parseCarbonShortcut("Alt+Shift+Nope") == nil)
    }
}
