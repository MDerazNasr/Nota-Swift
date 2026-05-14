import Foundation

public enum TagUtilities {
    public static func normalizeTagName(_ name: String) -> String {
        name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"^\/+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }

    public static func tagKey(_ name: String) -> String {
        normalizeTagName(name).lowercased()
    }

    public static func collectActiveTags(from tabs: [Tab]) -> [ItemTag] {
        var tags: [String: ItemTag] = [:]

        for tab in tabs {
            for item in tab.items {
                for tag in item.tags {
                    let key = tagKey(tag.name)
                    if key.isEmpty == false, tags[key] == nil {
                        tags[key] = tag
                    }
                }
            }
        }

        return tags.values.sorted { lhs, rhs in
            lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    public static func findTag(named name: String, in tags: [ItemTag]) -> ItemTag? {
        let key = tagKey(name)
        return tags.first { tagKey($0.name) == key }
    }

    public static func makeTag(name: String, colorIndex: Int = 0) -> ItemTag {
        let normalizedName = normalizeTagName(name)
        let color = ThemeCatalog.tagColors[colorIndex % ThemeCatalog.tagColors.count]
        return ItemTag(
            name: normalizedName,
            color: color,
            normalizedName: tagKey(normalizedName)
        )
    }
}
