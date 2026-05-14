import Foundation

public struct RichTextSpan: Codable, Equatable, Sendable {
    public var start: Int
    public var end: Int
    public var bold: Bool
    public var italic: Bool
    public var underline: Bool
    public var link: String?

    public init(
        start: Int,
        end: Int,
        bold: Bool = false,
        italic: Bool = false,
        underline: Bool = false,
        link: String? = nil
    ) {
        self.start = start
        self.end = end
        self.bold = bold
        self.italic = italic
        self.underline = underline
        self.link = link
    }
}

public struct CodableRichText: Codable, Equatable, Sendable {
    public var text: String
    public var spans: [RichTextSpan]

    public init(text: String, spans: [RichTextSpan]) {
        self.text = text
        self.spans = spans
    }

    public static let empty = CodableRichText(text: "", spans: [])
}
