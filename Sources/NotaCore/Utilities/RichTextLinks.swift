import Foundation

public extension CodableRichText {
    var firstLinkURLString: String? {
        spans.compactMap(\.link).first
    }
}
