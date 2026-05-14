import Foundation

public enum NotesNormalizer {
    public static func normalize(appState: AppState) -> AppState {
        let tabs = appState.tabs.isEmpty ? [AppDefaults.makeDefaultTab()] : appState.tabs.map(normalize(tab:))
        let activeTabId = tabs.contains(where: { $0.id == appState.activeTabId }) ? appState.activeTabId : tabs[0].id
        return AppState(tabs: tabs, activeTabId: activeTabId)
    }

    public static func normalize(tab: Tab) -> Tab {
        let title = normalizeTitle(tab.title)
        let items = tab.items.map(normalize(item:))
        return Tab(id: tab.id, title: title, items: items, createdAt: tab.createdAt)
    }

    public static func normalize(item: Item) -> Item {
        Item(
            id: item.id,
            richText: normalize(richText: item.richText),
            state: item.state,
            tags: normalize(tags: item.tags),
            createdAt: item.createdAt
        )
    }

    public static func normalize(richText: CodableRichText) -> CodableRichText {
        let count = richText.text.count
        let spans = richText.spans.compactMap { span -> RichTextSpan? in
            let start = max(0, min(span.start, count))
            let end = max(start, min(span.end, count))
            guard start < end else {
                return nil
            }

            return RichTextSpan(
                start: start,
                end: end,
                bold: span.bold,
                italic: span.italic,
                underline: span.underline,
                link: span.link
            )
        }

        return CodableRichText(text: richText.text, spans: spans)
    }

    public static func normalize(tags: [ItemTag]) -> [ItemTag] {
        tags.compactMap { normalize(tag: $0) }
    }

    public static func normalize(tag: ItemTag) -> ItemTag? {
        let trimmed = normalizeTagName(tag.name)
        guard trimmed.isEmpty == false else {
            return nil
        }

        return ItemTag(name: trimmed, color: tag.color, normalizedName: normalizeTagIdentity(trimmed))
    }

    public static func normalizeTitle(_ title: String) -> String {
        let trimmed = collapseWhitespace(title).trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled" : String(trimmed.prefix(40))
    }

    public static func normalizeTagName(_ value: String) -> String {
        collapseWhitespace(value)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    public static func normalizeTagIdentity(_ value: String) -> String {
        normalizeTagName(value).lowercased()
    }

    private static func collapseWhitespace(_ value: String) -> String {
        value.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }
}

public enum SettingsNormalizer {
    public static func normalize(settings: Settings) -> Settings {
        var settings = settings
        settings.font = FontOption(rawValue: settings.font.rawValue) ?? .jetBrainsMono
        settings.fontSize = min(max(settings.fontSize, 10), 20)
        settings.borderRadius = min(max(settings.borderRadius, 0), 12)
        settings.itemLimit = min(max(settings.itemLimit, 5), 50)
        settings.shortcuts = normalize(shortcuts: settings.shortcuts)
        settings.windowSize = normalize(windowSize: settings.windowSize)
        return settings
    }

    public static func normalize(shortcuts: ShortcutMap) -> ShortcutMap {
        var shortcuts = shortcuts

        if shortcuts.toggleWindow == "CommandOrControl+Shift+N" || shortcuts.toggleWindow == "Alt+Shift+N" {
            shortcuts.toggleWindow = AppDefaults.defaultShortcuts.toggleWindow
        }

        if shortcuts.renameTab == "CommandOrControl+Shift+R" {
            shortcuts.renameTab = ""
        }

        if shortcuts.editItem == "Enter" {
            shortcuts.editItem = "I"
        }

        return shortcuts
    }

    public static func normalize(windowSize: WindowSize?) -> WindowSize? {
        guard var windowSize else {
            return nil
        }

        if windowSize.width == AppDefaults.defaultWindowWidth, windowSize.height == AppDefaults.legacyWindowHeight {
            windowSize.height = AppDefaults.defaultWindowHeight
        }

        return windowSize
    }
}
