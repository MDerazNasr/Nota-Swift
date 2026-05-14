import AppKit

extension ItemEditorVim {
    static func selectCurrentCharacter(in textView: NotaTextView) {
        let location = min(textView.selectedRange().location, textView.string.count)
        let length = textView.string.isEmpty ? 0 : 1
        textView.vimState.visualAnchor = location
        textView.setSelectedRange(NSRange(location: location, length: length))
    }

    static func selectWholeTask(in textView: NotaTextView) {
        textView.vimState.visualAnchor = 0
        textView.setSelectedRange(NSRange(location: 0, length: textView.string.utf16.count))
    }

    static func collapseSelection(_ textView: NotaTextView) {
        let range = textView.selectedRange()
        textView.setSelectedRange(NSRange(location: range.location + range.length, length: 0))
        textView.vimState.visualAnchor = nil
    }

    static func moveByCharacter(in textView: NotaTextView, mode: ItemEditorMode, offset: Int) {
        if mode == .visual || mode == .visualLine {
            let anchor = textView.vimState.visualAnchor ?? textView.selectedRange().location
            let nextHead = clamp(currentHead(in: textView, anchor: anchor) + offset, min: 0, max: textView.string.count)
            setVisualSelection(in: textView, anchor: anchor, head: nextHead)
            return
        }

        let next = clamp(textView.selectedRange().location + offset, min: 0, max: textView.string.count)
        textView.setSelectedRange(NSRange(location: next, length: 0))
    }

    static func moveByWord(in textView: NotaTextView, mode: ItemEditorMode, motion: WordMotion, bigWord: Bool) {
        let text = textView.string
        let offset = textView.selectedRange().location
        let nextOffset = motion == .previousStart
            ? previousWordStart(in: text, offset: offset, bigWord: bigWord)
            : nextWordStart(in: text, offset: offset, bigWord: bigWord)
        setMotionSelection(in: textView, mode: mode, position: nextOffset)
    }

    static func jumpToBoundary(in textView: NotaTextView, boundary: Boundary, mode: ItemEditorMode) {
        setMotionSelection(in: textView, mode: mode, position: boundary == .start ? 0 : textView.string.count)
    }

    static func jumpToMatchingBracket(in textView: NotaTextView, mode: ItemEditorMode) {
        let text = textView.string
        let offset = max(0, min(text.count - 1, textView.selectedRange().location))
        guard let target = findMatchingBracket(in: text, offset: offset) else {
            return
        }

        setMotionSelection(in: textView, mode: mode, position: target)
    }

    static func search(in textView: NotaTextView, query: String?, direction: SearchDirection) {
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

    static func deleteUnderCursor(in textView: NotaTextView) {
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

    static func pasteAfterCursor(in textView: NotaTextView, clipboard: String?) {
        guard let clipboard, clipboard.isEmpty == false else {
            return
        }

        let insertionPoint = min(textView.selectedRange().location + 1, textView.string.count)
        replaceText(in: textView, range: NSRange(location: insertionPoint, length: 0), with: " \(clipboard)")
    }

    static func changeInnerWord(in textView: NotaTextView, bigWord: Bool) {
        guard let range = wordRange(in: textView, bigWord: bigWord) else {
            return
        }

        replaceText(in: textView, range: range, with: "")
    }

    static func deleteInsidePair(in textView: NotaTextView, open: String, close: String) {
        guard let range = pairRange(in: textView, open: open, close: close, includePair: false) else {
            return
        }

        replaceText(in: textView, range: range, with: "")
    }

    static func deleteAroundPair(in textView: NotaTextView, open: String, close: String) {
        guard let range = pairRange(in: textView, open: open, close: close, includePair: true) else {
            return
        }

        replaceText(in: textView, range: range, with: "")
    }

    static func changeHTMLTag(in textView: NotaTextView) {
        let text = textView.string as NSString
        let cursor = min(textView.selectedRange().location, text.length)
        let fullText = text as String
        let targetIndex = fullText.index(fullText.startIndex, offsetBy: min(cursor + 1, fullText.count))
        let openStart = fullText[..<targetIndex].lastIndex(of: "<")
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

    static func runExCommand(in textView: NotaTextView, command: String) {
        let nextText = runSubstitution(text: textView.string, command: command)
        guard nextText != textView.string else {
            return
        }

        replaceText(in: textView, range: NSRange(location: 0, length: textView.string.utf16.count), with: nextText)
    }
}

enum Boundary {
    case start
    case end
}

enum WordMotion {
    case nextStart
    case previousStart
}

enum SearchDirection {
    case next
    case previous
}
