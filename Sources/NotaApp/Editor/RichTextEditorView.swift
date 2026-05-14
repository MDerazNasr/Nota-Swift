import AppKit
import NotaCore
import SwiftUI

struct RichTextEditorView: NSViewRepresentable {
    final class Bridge: ObservableObject {
        weak var textView: NotaTextView?
        @Published var cursorRect: CGRect?

        @MainActor
        func focus() {
            guard let textView else {
                return
            }

            textView.window?.makeFirstResponder(textView)
        }
    }

    let bridge: Bridge
    let richText: CodableRichText
    let editable: Bool
    let fontName: String
    let fontSize: CGFloat
    @Binding var mode: ItemEditorMode
    let onChange: (CodableRichText) -> Void
    let onFocus: () -> Void
    let onExitEditor: () -> Void
    let onCheckItem: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder

        let textView = NotaTextView()
        textView.delegate = context.coordinator
        textView.isRichText = true
        textView.importsGraphics = false
        textView.drawsBackground = false
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.onCheckItem = onCheckItem
        textView.onModeChange = { nextMode in
            context.coordinator.parent.mode = nextMode
        }
        textView.onExitEditor = onExitEditor
        textView.onCursorRectChange = { nextRect in
            context.coordinator.parent.bridge.cursorRect = nextRect
        }
        bridge.textView = textView
        scrollView.documentView = textView
        context.coordinator.textView = textView
        apply(to: textView, coordinator: context.coordinator)
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else {
            return
        }

        apply(to: textView, coordinator: context.coordinator)
    }

    private func apply(to textView: NotaTextView, coordinator: Coordinator) {
        let attributed = AttributedStringCodec.makeAttributedString(
            from: richText,
            fontSize: fontSize,
            fontName: fontName
        )

        if textView.string != attributed.string || coordinator.lastRichText != richText {
            textView.textStorage?.setAttributedString(attributed)
            coordinator.lastRichText = richText
        }

        textView.isEditable = editable
        textView.isSelectable = true
        textView.editorMode = mode

        if editable && coordinator.wasEditable == false {
            mode = .insert
            textView.editorMode = .insert
            textView.setSelectedRange(NSRange(location: textView.string.count, length: 0))
            textView.window?.makeFirstResponder(textView)
            onFocus()
        }

        coordinator.wasEditable = editable
        textView.updateCursorRect()
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditorView
        weak var textView: NotaTextView?
        var lastRichText = CodableRichText.empty
        var wasEditable = false

        init(_ parent: RichTextEditorView) {
            self.parent = parent
        }

        func textDidBeginEditing(_ notification: Notification) {
            parent.onFocus()
        }

        func textDidChange(_ notification: Notification) {
            guard let textView else {
                return
            }

            let richText = AttributedStringCodec.makeRichText(from: textView.attributedString())
            lastRichText = richText
            parent.onChange(richText)
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            textView?.updateCursorRect()
        }
    }
}

final class NotaTextView: NSTextView {
    var editorMode: ItemEditorMode = .insert
    var onCheckItem: (() -> Void)?
    var onModeChange: ((ItemEditorMode) -> Void)?
    var onExitEditor: (() -> Void)?
    var onCursorRectChange: ((CGRect?) -> Void)?
    var vimState = ItemEditorVimState()

    override func keyDown(with event: NSEvent) {
        if (event.modifierFlags.contains(.command) || event.modifierFlags.contains(.control)),
           event.keyCode == 36 {
            onCheckItem?()
            return
        }

        if (event.modifierFlags.contains(.command) || event.modifierFlags.contains(.control)),
           let characters = event.charactersIgnoringModifiers?.lowercased(),
           ["b", "i", "u"].contains(characters) {
            toggleFormattingShortcut(characters)
            return
        }

        if ItemEditorVim.handle(
            event: event,
            textView: self,
            editorMode: editorMode,
            setEditorMode: { [weak self] nextMode in
                self?.editorMode = nextMode
                self?.onModeChange?(nextMode)
            },
            exitEditor: { [weak self] in
                self?.onExitEditor?()
            }
        ) {
            updateCursorRect()
            return
        }

        guard editorMode == .insert else {
            return
        }

        super.keyDown(with: event)
        updateCursorRect()
    }

    func updateCursorRect() {
        guard editorMode != .insert,
              let layoutManager,
              let textContainer else {
            onCursorRectChange?(nil)
            return
        }

        if string.isEmpty {
            onCursorRectChange?(CGRect(x: 0, y: 0, width: 9, height: 16))
            return
        }

        let range = selectedRange()
        let location = min(max(range.location, 0), max(0, string.count - 1))
        let glyphRange = layoutManager.glyphRange(forCharacterRange: NSRange(location: location, length: 1), actualCharacterRange: nil)
        var rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        rect.origin.x += textContainerInset.width
        rect.origin.y += textContainerInset.height
        rect.size.width = max(rect.size.width, editorMode == .visual || editorMode == .visualLine ? 2 : 9)
        rect.size.height = max(rect.size.height, 16)

        if range.location >= string.count {
            rect.origin.x = rect.maxX - rect.size.width
        }

        onCursorRectChange?(rect)
    }

    private func toggleFormattingShortcut(_ key: String) {
        switch key {
        case "b":
            toggleTrait(.boldFontMask)
        case "i":
            toggleTrait(.italicFontMask)
        case "u":
            toggleUnderlineStyle()
        default:
            break
        }
    }

    private func toggleTrait(_ trait: NSFontTraitMask) {
        guard let storage = textStorage else {
            return
        }

        let range = selectedRange().length > 0
            ? selectedRange()
            : NSRange(location: max(0, selectedRange().location - 1), length: min(1, string.count))

        storage.enumerateAttribute(.font, in: range) { value, attributeRange, _ in
            let font = (value as? NSFont) ?? .monospacedSystemFont(ofSize: 13, weight: .regular)
            let nextFont = NSFontManager.shared.convert(font, toHaveTrait: trait)
            storage.addAttribute(.font, value: nextFont, range: attributeRange)
        }
        didChangeText()
    }

    private func toggleUnderlineStyle() {
        guard let storage = textStorage else {
            return
        }

        let range = selectedRange().length > 0
            ? selectedRange()
            : NSRange(location: max(0, selectedRange().location - 1), length: min(1, string.count))

        storage.enumerateAttribute(.underlineStyle, in: range) { value, attributeRange, _ in
            let current = value as? Int ?? 0
            let next = current == 0 ? NSUnderlineStyle.single.rawValue : 0
            storage.addAttribute(.underlineStyle, value: next, range: attributeRange)
        }
        didChangeText()
    }
}
