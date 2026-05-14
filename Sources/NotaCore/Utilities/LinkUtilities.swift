import Foundation

public enum LinkUtilities {
    public static func normalizeHref(_ url: String) -> String {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasPrefix("mailto:") || trimmed.range(of: #"^[a-z][a-z0-9+.-]*:\/\/"#, options: .regularExpression) != nil {
            return trimmed
        }

        return "https://\(trimmed)"
    }
}
