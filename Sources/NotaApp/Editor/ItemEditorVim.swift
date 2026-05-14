import AppKit
import Foundation

@MainActor
enum ItemEditorVim {
    static func handle(
        event: NSEvent,
        textView: NotaTextView,
        editorMode: ItemEditorMode,
        setEditorMode: (ItemEditorMode) -> Void,
        exitEditor: () -> Void
    ) -> Bool {
        if editorMode == .insert {
            return handleInsertMode(event: event, textView: textView, setEditorMode: setEditorMode)
        }

        if handleSearchInput(event: event, textView: textView) {
            return true
        }

        if handleExCommandInput(event: event, textView: textView) {
            return true
        }

        if (event.modifierFlags.contains(.command) || event.modifierFlags.contains(.control)),
           event.charactersIgnoringModifiers?.lowercased() == "r" {
            textView.undoManager?.redo()
            ItemEditorVimBuffer.reset(&textView.vimState)
            return true
        }

        if event.keyCode == 53 {
            if editorMode == .visual || editorMode == .visualLine {
                collapseSelection(textView)
                setEditorMode(.normal)
            } else {
                exitEditor()
            }
            ItemEditorVimBuffer.reset(&textView.vimState)
            return true
        }

        if handleArrowMotion(event: event, textView: textView, editorMode: editorMode) {
            ItemEditorVimBuffer.reset(&textView.vimState)
            return true
        }

        if handleImmediateModeKey(event: event, textView: textView, editorMode: editorMode, setEditorMode: setEditorMode) {
            return true
        }

        return handleBufferedCommand(event: event, textView: textView, editorMode: editorMode, setEditorMode: setEditorMode)
    }

    nonisolated static func runSubstitution(text: String, command: String) -> String {
        guard let expression = try? NSRegularExpression(pattern: #"^%s/(.+)/(.*)/(g|gc)$"#) else {
            return text
        }

        let fullRange = NSRange(location: 0, length: command.utf16.count)
        guard let match = expression.firstMatch(in: command, range: fullRange),
              let oldRange = Range(match.range(at: 1), in: command),
              let newRange = Range(match.range(at: 2), in: command) else {
            return text
        }

        let oldText = String(command[oldRange])
        let newText = String(command[newRange])
        guard oldText.isEmpty == false else {
            return text
        }

        return text.replacingOccurrences(of: oldText, with: newText)
    }

    private static func handleInsertMode(
        event: NSEvent,
        textView: NotaTextView,
        setEditorMode: (ItemEditorMode) -> Void
    ) -> Bool {
        guard event.keyCode == 53 else {
            return false
        }

        setEditorMode(.normal)
        ItemEditorVimBuffer.reset(&textView.vimState)
        return true
    }

    private static func handleSearchInput(event: NSEvent, textView: NotaTextView) -> Bool {
        guard textView.vimState.pendingSearch != nil else {
            return false
        }

        let key = event.charactersIgnoringModifiers ?? ""

        if event.keyCode == 53 {
            textView.vimState.pendingSearch = nil
            textView.vimState.commandBuffer = ""
            return true
        }

        if key == "\u{7F}" {
            textView.vimState.pendingSearch?.removeLast()
            return true
        }

        if key == "\r" {
            search(in: textView, query: textView.vimState.pendingSearch, direction: .next)
            textView.vimState.lastSearch = textView.vimState.pendingSearch
            textView.vimState.pendingSearch = nil
            textView.vimState.commandBuffer = ""
            return true
        }

        if key.count == 1 {
            textView.vimState.pendingSearch?.append(key)
            return true
        }

        return true
    }

    private static func handleExCommandInput(event: NSEvent, textView: NotaTextView) -> Bool {
        guard textView.vimState.pendingExCommand != nil else {
            return false
        }

        let key = event.charactersIgnoringModifiers ?? ""

        if event.keyCode == 53 {
            textView.vimState.pendingExCommand = nil
            textView.vimState.commandBuffer = ""
            return true
        }

        if key == "\u{7F}" {
            textView.vimState.pendingExCommand?.removeLast()
            return true
        }

        if key == "\r" {
            runExCommand(in: textView, command: textView.vimState.pendingExCommand ?? "")
            textView.vimState.pendingExCommand = nil
            textView.vimState.commandBuffer = ""
            return true
        }

        if key.count == 1 {
            textView.vimState.pendingExCommand?.append(key)
            return true
        }

        return true
    }

    private static func handleImmediateModeKey(
        event: NSEvent,
        textView: NotaTextView,
        editorMode: ItemEditorMode,
        setEditorMode: (ItemEditorMode) -> Void
    ) -> Bool {
        switch event.charactersIgnoringModifiers {
        case "i":
            setEditorMode(.insert)
        case "a":
            moveByCharacter(in: textView, mode: .normal, offset: 1)
            setEditorMode(.insert)
        case "I":
            jumpToBoundary(in: textView, boundary: .start, mode: .normal)
            setEditorMode(.insert)
        case "A":
            textView.setSelectedRange(NSRange(location: textView.string.count, length: 0))
            setEditorMode(.insert)
        case "v":
            if editorMode == .visual {
                collapseSelection(textView)
                setEditorMode(.normal)
                textView.vimState.visualAnchor = nil
            } else {
                selectCurrentCharacter(in: textView)
                setEditorMode(.visual)
            }
        case "V":
            selectWholeTask(in: textView)
            setEditorMode(.visualLine)
        default:
            return false
        }

        ItemEditorVimBuffer.reset(&textView.vimState)
        return true
    }

    private static func handleArrowMotion(event: NSEvent, textView: NotaTextView, editorMode: ItemEditorMode) -> Bool {
        switch event.keyCode {
        case 123:
            moveByCharacter(in: textView, mode: editorMode, offset: -1)
        case 124:
            moveByCharacter(in: textView, mode: editorMode, offset: 1)
        case 125:
            jumpToBoundary(in: textView, boundary: .end, mode: editorMode)
        case 126:
            jumpToBoundary(in: textView, boundary: .start, mode: editorMode)
        default:
            return false
        }
        return true
    }

    private static func handleBufferedCommand(
        event: NSEvent,
        textView: NotaTextView,
        editorMode: ItemEditorMode,
        setEditorMode: (ItemEditorMode) -> Void
    ) -> Bool {
        guard let key = event.charactersIgnoringModifiers,
              let command = ItemEditorVimBuffer.recordCommandKey(state: &textView.vimState, key: key) else {
            return false
        }

        if ["g", "y", "d", "c", "ci", "di", "da"].contains(command) {
            return true
        }

        switch command {
        case "u":
            textView.undoManager?.undo()
        case "h", "Backspace":
            moveByCharacter(in: textView, mode: editorMode, offset: -1)
        case "l", " ":
            moveByCharacter(in: textView, mode: editorMode, offset: 1)
        case "w":
            moveByWord(in: textView, mode: editorMode, motion: .nextStart, bigWord: false)
        case "W":
            moveByWord(in: textView, mode: editorMode, motion: .nextStart, bigWord: true)
        case "b":
            moveByWord(in: textView, mode: editorMode, motion: .previousStart, bigWord: false)
        case "B":
            moveByWord(in: textView, mode: editorMode, motion: .previousStart, bigWord: true)
        case "0", "^":
            jumpToBoundary(in: textView, boundary: .start, mode: editorMode)
        case "$":
            jumpToBoundary(in: textView, boundary: .end, mode: editorMode)
        case "gg":
            jumpToBoundary(in: textView, boundary: .start, mode: editorMode)
        case "G":
            jumpToBoundary(in: textView, boundary: .end, mode: editorMode)
        case "%":
            jumpToMatchingBracket(in: textView, mode: editorMode)
        case "/":
            textView.vimState.pendingSearch = ""
            return true
        case ":":
            textView.vimState.pendingExCommand = ""
            return true
        case "n":
            search(in: textView, query: textView.vimState.lastSearch, direction: .next)
        case "N":
            search(in: textView, query: textView.vimState.lastSearch, direction: .previous)
        case "x", "Delete":
            deleteUnderCursor(in: textView)
        case "yy":
            textView.vimState.clipboard = textView.string
        case "p":
            pasteAfterCursor(in: textView, clipboard: textView.vimState.clipboard)
        case "dd":
            textView.vimState.clipboard = textView.string
            replaceText(in: textView, range: NSRange(location: 0, length: textView.string.utf16.count), with: "")
        case "ciw":
            changeInnerWord(in: textView, bigWord: false)
            setEditorMode(.insert)
        case "ciW":
            changeInnerWord(in: textView, bigWord: true)
            setEditorMode(.insert)
        case "di(":
            deleteInsidePair(in: textView, open: "(", close: ")")
        case "da(":
            deleteAroundPair(in: textView, open: "(", close: ")")
        case "cit":
            changeHTMLTag(in: textView)
            setEditorMode(.insert)
        default:
            ItemEditorVimBuffer.reset(&textView.vimState)
            return false
        }

        ItemEditorVimBuffer.reset(&textView.vimState)
        return true
    }
}
