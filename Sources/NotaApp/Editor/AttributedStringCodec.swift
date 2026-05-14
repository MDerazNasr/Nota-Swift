import AppKit
import NotaCore

enum AttributedStringCodec {
    static func makeAttributedString(from richText: CodableRichText, fontSize: CGFloat, fontName: String) -> NSAttributedString {
        let attributed = NSMutableAttributedString(string: richText.text)
        let baseFont = NSFont(name: fontName, size: fontSize) ?? .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        attributed.addAttribute(.font, value: baseFont, range: NSRange(location: 0, length: attributed.length))
        attributed.addAttribute(.foregroundColor, value: NSColor.labelColor, range: NSRange(location: 0, length: attributed.length))

        for span in NotesNormalizer.normalize(richText: richText).spans {
            let range = NSRange(location: span.start, length: span.end - span.start)
            var traits = NSFontDescriptor.SymbolicTraits()
            if span.bold {
                traits.insert(.bold)
            }
            if span.italic {
                traits.insert(.italic)
            }

            let descriptor = baseFont.fontDescriptor.withSymbolicTraits(traits)
            let font = NSFont(descriptor: descriptor, size: fontSize) ?? baseFont
            attributed.addAttribute(.font, value: font, range: range)

            if span.underline {
                attributed.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            }

            if let link = span.link, let url = URL(string: link) {
                attributed.addAttribute(.link, value: url, range: range)
                attributed.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: range)
            }
        }

        return attributed
    }

    static func makeRichText(from attributedString: NSAttributedString) -> CodableRichText {
        let text = attributedString.string
        var spans: [RichTextSpan] = []

        attributedString.enumerateAttributes(in: NSRange(location: 0, length: attributedString.length)) { attributes, range, _ in
            let font = attributes[.font] as? NSFont
            let traits = font?.fontDescriptor.symbolicTraits ?? []
            let underline = (attributes[.underlineStyle] as? Int ?? 0) != 0
            let link: String?

            if let url = attributes[.link] as? URL {
                link = url.absoluteString
            } else if let value = attributes[.link] as? String {
                link = value
            } else {
                link = nil
            }

            if traits.isEmpty, underline == false, link == nil {
                return
            }

            spans.append(
                RichTextSpan(
                    start: range.location,
                    end: range.location + range.length,
                    bold: traits.contains(.bold),
                    italic: traits.contains(.italic),
                    underline: underline,
                    link: link
                )
            )
        }

        return NotesNormalizer.normalize(richText: CodableRichText(text: text, spans: spans))
    }
}
