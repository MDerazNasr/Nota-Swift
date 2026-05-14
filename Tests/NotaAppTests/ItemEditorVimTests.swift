import Testing
@testable import NotaApp

struct ItemEditorVimTests {
    @Test
    func substitutionReplacesAllMatches() {
        let output = ItemEditorVim.runSubstitution(
            text: "alpha beta alpha",
            command: "%s/alpha/gamma/g"
        )

        #expect(output == "gamma beta gamma")
    }

    @Test
    func commandBufferRecognizesCompositeCommands() {
        var state = ItemEditorVimState()
        #expect(ItemEditorVimBuffer.recordCommandKey(state: &state, key: "d") == "d")
        #expect(ItemEditorVimBuffer.recordCommandKey(state: &state, key: "d") == "dd")

        var changeState = ItemEditorVimState()
        #expect(ItemEditorVimBuffer.recordCommandKey(state: &changeState, key: "c") == "c")
        #expect(ItemEditorVimBuffer.recordCommandKey(state: &changeState, key: "i") == "ci")
        #expect(ItemEditorVimBuffer.recordCommandKey(state: &changeState, key: "w") == "ciw")
    }
}
