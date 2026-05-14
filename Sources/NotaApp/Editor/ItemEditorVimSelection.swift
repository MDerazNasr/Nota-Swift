import AppKit

extension ItemEditorVim {
    static func replaceText(in textView: NotaTextView, range: NSRange, with string: String) {
        textView.textStorage?.replaceCharacters(in: range, with: string)
        textView.setSelectedRange(NSRange(location: min(range.location + string.count, textView.string.count), length: 0))
        textView.didChangeText()
    }

    static func wordRange(in textView: NotaTextView, bigWord: Bool) -> NSRange? {
        let text = textView.string
        let offset = min(textView.selectedRange().location, text.count)
        let start = findWordBoundary(in: text, offset: offset, direction: .backward, bigWord: bigWord)
        let end = findWordBoundary(in: text, offset: offset, direction: .forward, bigWord: bigWord)
        guard start != end else {
            return nil
        }
        return NSRange(location: start, length: end - start)
    }

    static func pairRange(in textView: NotaTextView, open: String, close: String, includePair: Bool) -> NSRange? {
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

    static func setMotionSelection(in textView: NotaTextView, mode: ItemEditorMode, position: Int) {
        let next = clamp(position, min: 0, max: textView.string.count)

        if mode == .visual || mode == .visualLine {
            let anchor = textView.vimState.visualAnchor ?? textView.selectedRange().location
            setVisualSelection(in: textView, anchor: anchor, head: next)
        } else {
            textView.setSelectedRange(NSRange(location: next, length: 0))
        }
    }

    static func setVisualSelection(in textView: NotaTextView, anchor: Int, head: Int) {
        let clampedAnchor = clamp(anchor, min: 0, max: textView.string.count)
        let clampedHead = clamp(head, min: 0, max: textView.string.count)
        textView.vimState.visualAnchor = clampedAnchor
        textView.setSelectedRange(NSRange(location: min(clampedAnchor, clampedHead), length: abs(clampedHead - clampedAnchor)))
    }

    static func currentHead(in textView: NotaTextView, anchor: Int) -> Int {
        let range = textView.selectedRange()
        let upper = range.location + range.length
        return range.location == anchor ? upper : range.location
    }

    static func nextWordStart(in text: String, offset: Int, bigWord: Bool) -> Int {
        let characters = Array(text)
        var index = min(offset + 1, characters.count)
        while index < characters.count, isWordCharacter(characters[index], bigWord: bigWord) { index += 1 }
        while index < characters.count, isWordCharacter(characters[index], bigWord: bigWord) == false { index += 1 }
        return index
    }

    static func previousWordStart(in text: String, offset: Int, bigWord: Bool) -> Int {
        let characters = Array(text)
        var index = max(offset - 1, 0)
        while index > 0, isWordCharacter(characters[index], bigWord: bigWord) == false { index -= 1 }
        while index > 0, isWordCharacter(characters[index - 1], bigWord: bigWord) { index -= 1 }
        return index
    }

    static func findWordBoundary(in text: String, offset: Int, direction: Direction, bigWord: Bool) -> Int {
        let characters = Array(text)
        var index = min(max(offset, 0), characters.count)
        if direction == .backward {
            while index > 0, isWordCharacter(characters[index - 1], bigWord: bigWord) { index -= 1 }
        } else {
            while index < characters.count, isWordCharacter(characters[index], bigWord: bigWord) { index += 1 }
        }
        return index
    }

    static func findMatchingBracket(in text: String, offset: Int) -> Int? {
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

    static func clamp(_ value: Int, min: Int, max: Int) -> Int {
        Swift.min(Swift.max(value, min), max)
    }

    static func isWordCharacter(_ character: Character, bigWord: Bool) -> Bool {
        bigWord ? character.isWhitespace == false : (character.isLetter || character.isNumber || character == "_")
    }

    static func scanForMatch(in characters: [Character], offset: Int, start: Character, end: Character, step: Int) -> Int? {
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
}

enum Direction {
    case backward
    case forward
}
