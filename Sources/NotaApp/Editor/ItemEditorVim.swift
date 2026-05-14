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

    private static func selectCurrentCharacter(in textView: NotaTextView) {
        let location = min(textView.selectedRange().location, textView.string.count)
        let length = textView.string.isEmpty ? 0 : 1
        textView.vimState.visualAnchor = location
        textView.setSelectedRange(NSRange(location: location, length: length))
    }

    private static func selectWholeTask(in textView: NotaTextView) {
        textView.vimState.visualAnchor = 0
        textView.setSelectedRange(NSRange(location: 0, length: textView.string.utf16.count))
    }

    private static func collapseSelection(_ textView: NotaTextView) {
        let range = textView.selectedRange()
        textView.setSelectedRange(NSRange(location: range.location + range.length, length: 0))
        textView.vimState.visualAnchor = nil
    }

    private static func moveByCharacter(in textView: NotaTextView, mode: ItemEditorMode, offset: Int) {
        if mode == .visual || mode == .visualLine {
            let anchor = textView.vimState.visualAnchor ?? textView.selectedRange().location
            let nextHead = clamp(currentHead(in: textView, anchor: anchor) + offset, min: 0, max: textView.string.count)
            setVisualSelection(in: textView, anchor: anchor, head: nextHead)
            return
        }

        let next = clamp(textView.selectedRange().location + offset, min: 0, max: textView.string.count)
        textView.setSelectedRange(NSRange(location: next, length: 0))
    }

    private static func moveByWord(in textView: NotaTextView, mode: ItemEditorMode, motion: WordMotion, bigWord: Bool) {
        let text = textView.string
        let offset = textView.selectedRange().location
        let nextOffset = motion == .previousStart
            ? previousWordStart(in: text, offset: offset, bigWord: bigWord)
            : nextWordStart(in: text, offset: offset, bigWord: bigWord)
        setMotionSelection(in: textView, mode: mode, position: nextOffset)
    }

    private static func jumpToBoundary(in textView: NotaTextView, boundary: Boundary, mode: ItemEditorMode) {
        setMotionSelection(in: textView, mode: mode, position: boundary == .start ? 0 : textView.string.count)
    }

    private static func jumpToMatchingBracket(in textView: NotaTextView, mode: ItemEditorMode) {
        let text = textView.string
        let offset = max(0, min(text.count - 1, textView.selectedRange().location))
        guard let target = findMatchingBracket(in: text, offset: offset) else {
            return
        }

        setMotionSelection(in: textView, mode: mode, position: target)
    }

    private static func setMotionSelection(in textView: NotaTextView, mode: ItemEditorMode, position: Int) {
        let next = clamp(position, min: 0, max: textView.string.count)

        if mode == .visual || mode == .visualLine {
            let anchor = textView.vimState.visualAnchor ?? textView.selectedRange().location
            setVisualSelection(in: textView, anchor: anchor, head: next)
        } else {
            textView.setSelectedRange(NSRange(location: next, length: 0))
        }
    }

    private static func setVisualSelection(in textView: NotaTextView, anchor: Int, head: Int) {
        let clampedAnchor = clamp(anchor, min: 0, max: textView.string.count)
        let clampedHead = clamp(head, min: 0, max: textView.string.count)
        textView.vimState.visualAnchor = clampedAnchor
        textView.setSelectedRange(NSRange(location: min(clampedAnchor, clampedHead), length: abs(clampedHead - clampedAnchor)))
    }

    private static func currentHead(in textView: NotaTextView, anchor: Int) -> Int {
        let range = textView.selectedRange()
        let upper = range.location + range.length
        return range.location == anchor ? upper : range.location
    }

    private static func search(in textView: NotaTextView, query: String?, direction: SearchDirection) {
        guard let query, query.isEmpty == false else {
            return
        }

        let text = textView.string as NSString
        let current = max(0, textView.selectedRange().location)
        let foundRange: NSRange

        if direction == .next {
            let nextRange = NSRange(location: min(current + 1, text.length), length: max(0, text.length - current - 1))
            let first = text.range(of: query, options: [], range: nextRange)
            foundRange = first.location != NSNotFound ? first : text.range(of: query)
        } else {
            let first = text.range(of: query, options: .backwards, range: NSRange(location: 0, length: max(0, current - 1)))
            foundRange = first.location != NSNotFound ? first : text.range(of: query, options: .backwards)
        }

        guard foundRange.location != NSNotFound else {
            return
        }

        textView.vimState.visualAnchor = foundRange.location
        textView.setSelectedRange(foundRange)
    }

    private static func deleteUnderCursor(in textView: NotaTextView) {
        let range = textView.selectedRange()
        if range.length > 0 {
            replaceText(in: textView, range: range, with: "")
            return
        }

        guard range.location < textView.string.count else {
            return
        }

        replaceText(in: textView, range: NSRange(location: range.location, length: 1), with: "")
    }

    private static func pasteAfterCursor(in textView: NotaTextView, clipboard: String?) {
        guard let clipboard, clipboard.isEmpty == false else {
            return
        }

        let insertionPoint = min(textView.selectedRange().location + 1, textView.string.count)
        replaceText(in: textView, range: NSRange(location: insertionPoint, length: 0), with: " \(clipboard)")
    }

    private static func changeInnerWord(in textView: NotaTextView, bigWord: Bool) {
        guard let range = wordRange(in: textView, bigWord: bigWord) else {
            return
        }

        replaceText(in: textView, range: range, with: "")
    }

    private static func deleteInsidePair(in textView: NotaTextView, open: String, close: String) {
        guard let range = pairRange(in: textView, open: open, close: close, includePair: false) else {
            return
        }

        replaceText(in: textView, range: range, with: "")
    }

    private static func deleteAroundPair(in textView: NotaTextView, open: String, close: String) {
        guard let range = pairRange(in: textView, open: open, close: close, includePair: true) else {
            return
        }

        replaceText(in: textView, range: range, with: "")
    }

    private static func changeHTMLTag(in textView: NotaTextView) {
        let text = textView.string as NSString
        let cursor = min(textView.selectedRange().location, text.length)
        let fullText = text as String
        let openStart = fullText.lastIndex(of: "<", before: fullText.index(fullText.startIndex, offsetBy: min(cursor + 1, fullText.count)))
        guard let openStart else {
            return
        }

        let openStartOffset = fullText.distance(from: fullText.startIndex, to: openStart)
        guard let openEndIndex = fullText[openStart...].firstIndex(of: ">") else {
            return
        }

        let openEndOffset = fullText.distance(from: fullText.startIndex, to: openEndIndex)
        let tagSlice = String(fullText[fullText.index(fullText.startIndex, offsetBy: openStartOffset)...fullText.index(fullText.startIndex, offsetBy: openEndOffset)])
        guard let tagName = tagSlice.firstMatch(of: /<\s*([A-Za-z][\w:-]*)\b/)?.1 else {
            return
        }

        guard let closeRange = fullText.range(
            of: "</\(tagName)>",
            options: [],
            range: fullText.index(fullText.startIndex, offsetBy: cursor)..<fullText.endIndex
        ) else {
            return
        }

        let closeOffset = fullText.distance(from: fullText.startIndex, to: closeRange.lowerBound)
        replaceText(in: textView, range: NSRange(location: openEndOffset + 1, length: closeOffset - openEndOffset - 1), with: "")
    }

    private static func runExCommand(in textView: NotaTextView, command: String) {
        let nextText = runSubstitution(text: textView.string, command: command)
        guard nextText != textView.string else {
            return
        }

        replaceText(in: textView, range: NSRange(location: 0, length: textView.string.utf16.count), with: nextText)
    }

    private static func replaceText(in textView: NotaTextView, range: NSRange, with string: String) {
        textView.textStorage?.replaceCharacters(in: range, with: string)
        textView.setSelectedRange(NSRange(location: min(range.location + string.count, textView.string.count), length: 0))
        textView.didChangeText()
    }

    private static func wordRange(in textView: NotaTextView, bigWord: Bool) -> NSRange? {
        let text = textView.string
        let offset = min(textView.selectedRange().location, text.count)
        let start = findWordBoundary(in: text, offset: offset, direction: .backward, bigWord: bigWord)
        let end = findWordBoundary(in: text, offset: offset, direction: .forward, bigWord: bigWord)
        guard start != end else {
            return nil
        }
        return NSRange(location: start, length: end - start)
    }

    private static func pairRange(in textView: NotaTextView, open: String, close: String, includePair: Bool) -> NSRange? {
        let text = textView.string as NSString
        let cursor = min(textView.selectedRange().location, text.length)
        let openRange = text.range(of: open, options: .backwards, range: NSRange(location: 0, length: cursor))
        let closeRange = text.range(of: close, options: [], range: NSRange(location: cursor, length: max(0, text.length - cursor)))

        guard openRange.location != NSNotFound,
              closeRange.location != NSNotFound,
              closeRange.location > openRange.location else {
            return nil
        }

        if includePair {
            return NSRange(location: openRange.location, length: closeRange.location + closeRange.length - openRange.location)
        }

        let location = openRange.location + openRange.length
        return NSRange(location: location, length: max(0, closeRange.location - location))
    }

    private static func nextWordStart(in text: String, offset: Int, bigWord: Bool) -> Int {
        let characters = Array(text)
        var index = min(offset + 1, characters.count)
        while index < characters.count, isWordCharacter(characters[index], bigWord: bigWord) { index += 1 }
        while index < characters.count, isWordCharacter(characters[index], bigWord: bigWord) == false { index += 1 }
        return index
    }

    private static func previousWordStart(in text: String, offset: Int, bigWord: Bool) -> Int {
        let characters = Array(text)
        var index = max(offset - 1, 0)
        while index > 0, isWordCharacter(characters[index], bigWord: bigWord) == false { index -= 1 }
        while index > 0, isWordCharacter(characters[index - 1], bigWord: bigWord) { index -= 1 }
        return index
    }

    private static func findWordBoundary(in text: String, offset: Int, direction: Direction, bigWord: Bool) -> Int {
        let characters = Array(text)
        var index = min(max(offset, 0), characters.count)
        if direction == .backward {
            while index > 0, isWordCharacter(characters[index - 1], bigWord: bigWord) { index -= 1 }
        } else {
            while index < characters.count, isWordCharacter(characters[index], bigWord: bigWord) { index += 1 }
        }
        return index
    }

    private static func findMatchingBracket(in text: String, offset: Int) -> Int? {
        let characters = Array(text)
        guard characters.indices.contains(offset) else {
            return nil
        }

        let pairs: [Character: Character] = ["(": ")", "[": "]", "{": "}"]
        let reversePairs: [Character: Character] = [")": "(", "]": "[", "}": "{"]
        let character = characters[offset]

        if let end = pairs[character] {
            return scanForMatch(in: characters, offset: offset, start: character, end: end, step: 1)
        }

        if let start = reversePairs[character] {
            return scanForMatch(in: characters, offset: offset, start: character, end: start, step: -1)
        }

        return nil
    }

    private static func scanForMatch(in characters: [Character], offset: Int, start: Character, end: Character, step: Int) -> Int? {
        var depth = 0
        var index = offset

        while characters.indices.contains(index) {
            let character = characters[index]
            if character == start {
                depth += 1
            } else if character == end {
                depth -= 1
            }

            if depth == 0 {
                return index
            }

            index += step
        }

        return nil
    }

    private static func isWordCharacter(_ character: Character, bigWord: Bool) -> Bool {
        bigWord ? character.isWhitespace == false : (character.isLetter || character.isNumber || character == "_")
    }

    private static func clamp(_ value: Int, min: Int, max: Int) -> Int {
        Swift.min(Swift.max(value, min), max)
    }
}

private enum Boundary {
    case start
    case end
}

private enum WordMotion {
    case nextStart
    case previousStart
}

private enum SearchDirection {
    case next
    case previous
}

private enum Direction {
    case backward
    case forward
}

private extension String {
    func lastIndex(of character: Character, before index: Index) -> Index? {
        self[..<index].lastIndex(of: character)
    }
}
