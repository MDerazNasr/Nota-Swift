import Foundation

public enum SlashCommand: String, Codable, Equatable, Sendable {
    case link
}

public enum SlashMenuItem: Equatable, Sendable {
    case command(id: String, command: SlashCommand, label: String, description: String)
    case tag(id: String, tag: ItemTag, label: String, description: String)
    case createTag(id: String, name: String, label: String, description: String)
}

public enum SlashCommandUtilities {
    public static let commands: [SlashCommand] = [.link]

    public static func buildItems(
        query: String,
        availableTags: [ItemTag],
        itemTags: [ItemTag] = []
    ) -> [SlashMenuItem] {
        let normalizedQuery = TagUtilities.normalizeTagName(query)
        let queryKey = TagUtilities.tagKey(normalizedQuery)
        let itemTagKeys = Set(itemTags.map { TagUtilities.tagKey($0.name) })
        var items: [SlashMenuItem] = commands
            .filter { queryKey.isEmpty || $0.rawValue == queryKey }
            .map { command in
                .command(
                    id: "command:\(command.rawValue)",
                    command: command,
                    label: "/\(command.rawValue)",
                    description: "Insert hyperlink"
                )
            }

        let matchingTags = availableTags.filter { tag in
            let key = TagUtilities.tagKey(tag.name)
            return itemTagKeys.contains(key) == false && key.hasPrefix(queryKey)
        }

        items.append(contentsOf: matchingTags.map { tag in
            .tag(
                id: "tag:\(TagUtilities.tagKey(tag.name))",
                tag: tag,
                label: tag.name,
                description: "Add tag"
            )
        })

        let exactTag = TagUtilities.findTag(named: normalizedQuery, in: availableTags)
        let exactCommand = commands.contains { $0.rawValue == queryKey }

        if normalizedQuery.isEmpty == false, exactTag == nil, exactCommand == false {
            items.append(
                .createTag(
                    id: "create-tag:\(queryKey)",
                    name: normalizedQuery,
                    label: normalizedQuery,
                    description: "Create tag"
                )
            )
        }

        return items
    }
}
