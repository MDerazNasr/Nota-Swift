import NotaCore

enum SettingsBehaviorKey: String, Hashable {
    case openOnStartup
    case showInDock
    case showInMenuBar
}

enum SettingsShortcutCaptureKey: String, Hashable {
    case toggleWindow
    case openSettings
    case newTab
    case deleteTab
    case moveTabLeft
    case moveTabRight
    case createItemBelow
    case createItemAbove
    case editItem
    case deleteItem
    case checkItem
    case openItemLink
    case sortByTag
    case enterMoveMode
    case undo

    var title: String {
        switch self {
        case .toggleWindow:
            "Toggle window"
        case .openSettings:
            "Open settings"
        case .newTab:
            "New tab"
        case .deleteTab:
            "Delete list"
        case .moveTabLeft:
            "Move tab left"
        case .moveTabRight:
            "Move tab right"
        case .createItemBelow:
            "New item below"
        case .createItemAbove:
            "New item above"
        case .editItem:
            "Edit focused item"
        case .deleteItem:
            "Delete focused item"
        case .checkItem:
            "Check item"
        case .openItemLink:
            "Open item link"
        case .sortByTag:
            "Toggle tag sort"
        case .enterMoveMode:
            "Enter move mode"
        case .undo:
            "Undo"
        }
    }

    func value(from shortcuts: ShortcutMap) -> String {
        switch self {
        case .toggleWindow:
            shortcuts.toggleWindow
        case .openSettings:
            shortcuts.openSettings
        case .newTab:
            shortcuts.newTab
        case .deleteTab:
            shortcuts.deleteTab
        case .moveTabLeft:
            shortcuts.moveTabLeft
        case .moveTabRight:
            shortcuts.moveTabRight
        case .createItemBelow:
            shortcuts.createItemBelow
        case .createItemAbove:
            shortcuts.createItemAbove
        case .editItem:
            shortcuts.editItem
        case .deleteItem:
            shortcuts.deleteItem
        case .checkItem:
            shortcuts.checkItem
        case .openItemLink:
            shortcuts.openItemLink
        case .sortByTag:
            shortcuts.sortByTag
        case .enterMoveMode:
            shortcuts.enterMoveMode
        case .undo:
            shortcuts.undo
        }
    }

    func assign(_ value: String, to shortcuts: inout ShortcutMap) {
        switch self {
        case .toggleWindow:
            shortcuts.toggleWindow = value
        case .openSettings:
            shortcuts.openSettings = value
        case .newTab:
            shortcuts.newTab = value
        case .deleteTab:
            shortcuts.deleteTab = value
        case .moveTabLeft:
            shortcuts.moveTabLeft = value
        case .moveTabRight:
            shortcuts.moveTabRight = value
        case .createItemBelow:
            shortcuts.createItemBelow = value
        case .createItemAbove:
            shortcuts.createItemAbove = value
        case .editItem:
            shortcuts.editItem = value
        case .deleteItem:
            shortcuts.deleteItem = value
        case .checkItem:
            shortcuts.checkItem = value
        case .openItemLink:
            shortcuts.openItemLink = value
        case .sortByTag:
            shortcuts.sortByTag = value
        case .enterMoveMode:
            shortcuts.enterMoveMode = value
        case .undo:
            shortcuts.undo = value
        }
    }
}

enum SettingsRowKind: Hashable {
    case theme
    case font
    case fontSize
    case borderRadius
    case itemLimit
    case toggle(SettingsBehaviorKey)
    case hotkey(SettingsShortcutCaptureKey)
    case reference
}

struct SettingsRowDescriptor: Identifiable, Hashable {
    let id: String
    let index: Int
    let title: String
    let kind: SettingsRowKind
    let value: String?
}

struct SettingsSectionDescriptor: Identifiable, Hashable {
    let id: String
    let title: String
    let rows: [SettingsRowDescriptor]
}

let appearanceSettingsRows: [SettingsRowDescriptor] = [
    .init(id: "theme", index: 0, title: "Theme", kind: .theme, value: nil),
    .init(id: "font", index: 1, title: "Font", kind: .font, value: nil),
    .init(id: "fontSize", index: 2, title: "Font Size", kind: .fontSize, value: nil),
    .init(id: "radius", index: 3, title: "Radius", kind: .borderRadius, value: nil),
    .init(id: "itemLimit", index: 4, title: "Item Limit", kind: .itemLimit, value: nil),
]

let navigationSettingsSections: [SettingsSectionDescriptor] = {
    var nextIndex = 0

    func row(_ id: String, _ title: String, _ kind: SettingsRowKind, value: String? = nil) -> SettingsRowDescriptor {
        defer { nextIndex += 1 }
        return SettingsRowDescriptor(id: id, index: nextIndex, title: title, kind: kind, value: value)
    }

    return [
        .init(
            id: "behavior",
            title: "Behavior",
            rows: [
                row("openOnStartup", "Open on startup", .toggle(.openOnStartup)),
                row("showInDock", "Show in dock", .toggle(.showInDock)),
                row("showInMenuBar", "Show in menu bar", .toggle(.showInMenuBar)),
            ]
        ),
        .init(
            id: "window",
            title: "Window",
            rows: [
                row("toggleWindow", SettingsShortcutCaptureKey.toggleWindow.title, .hotkey(.toggleWindow)),
                row("openSettings", SettingsShortcutCaptureKey.openSettings.title, .hotkey(.openSettings)),
            ]
        ),
        .init(
            id: "tabs",
            title: "Tabs",
            rows: [
                row("newTab", SettingsShortcutCaptureKey.newTab.title, .hotkey(.newTab)),
                row("deleteTab", SettingsShortcutCaptureKey.deleteTab.title, .hotkey(.deleteTab)),
                row("moveTabLeft", SettingsShortcutCaptureKey.moveTabLeft.title, .hotkey(.moveTabLeft)),
                row("moveTabRight", SettingsShortcutCaptureKey.moveTabRight.title, .hotkey(.moveTabRight)),
            ]
        ),
        .init(
            id: "itemEditing",
            title: "Item editing",
            rows: [
                row("createItemBelow", SettingsShortcutCaptureKey.createItemBelow.title, .hotkey(.createItemBelow)),
                row("createItemAbove", SettingsShortcutCaptureKey.createItemAbove.title, .hotkey(.createItemAbove)),
                row("editItem", SettingsShortcutCaptureKey.editItem.title, .hotkey(.editItem)),
                row("deleteItem", SettingsShortcutCaptureKey.deleteItem.title, .hotkey(.deleteItem)),
                row("checkItem", SettingsShortcutCaptureKey.checkItem.title, .hotkey(.checkItem)),
                row("openItemLink", SettingsShortcutCaptureKey.openItemLink.title, .hotkey(.openItemLink)),
                row("sortByTag", SettingsShortcutCaptureKey.sortByTag.title, .hotkey(.sortByTag)),
            ]
        ),
        .init(
            id: "itemMovement",
            title: "Item movement",
            rows: [
                row("enterMoveMode", SettingsShortcutCaptureKey.enterMoveMode.title, .hotkey(.enterMoveMode)),
                row("undo", SettingsShortcutCaptureKey.undo.title, .hotkey(.undo)),
            ]
        ),
        .init(
            id: "appNavigation",
            title: "App navigation",
            rows: [
                row("appNavMoveCursor", "Move cursor", .reference, value: "J/K"),
                row("appNavSwitchTabs", "Switch tabs", .reference, value: "H/L"),
                row("appNavMoveSettings", "Move settings selector", .reference, value: "J/K"),
                row("appNavAdjustSettings", "Adjust selected setting", .reference, value: "Left/Right"),
                row("appNavCycleThemeX", "Cycle color schemes", .reference, value: "Left/Right on theme"),
                row("appNavCycleThemeY", "Cycle color schemes", .reference, value: "Up/Down on theme"),
            ]
        ),
        .init(
            id: "slashMenu",
            title: "Slash menu",
            rows: [
                row("slashLink", "Create link", .reference, value: "/link"),
                row("slashTag", "Create or add tag", .reference, value: "/tag"),
                row("slashUse", "Use suggestion", .reference, value: "Enter"),
            ]
        ),
        .init(
            id: "taskLinks",
            title: "Task links",
            rows: [
                row("taskLinkNext", "Move focus to URL", .reference, value: "Tab / N"),
                row("taskLinkPrev", "Move focus to Label", .reference, value: "Shift+Tab / n"),
                row("taskLinkInsert", "Insert link", .reference, value: "Enter"),
            ]
        ),
        .init(
            id: "taskVimModes",
            title: "Task Vim modes",
            rows: [
                row("vimEsc", "Normal mode", .reference, value: "Esc"),
                row("vimInsert", "Insert mode", .reference, value: "i / A"),
                row("vimVisual", "Visual mode", .reference, value: "v / V"),
                row("vimFormat", "Format selection", .reference, value: "Cmd+B / I / U"),
            ]
        ),
        .init(
            id: "taskVimMovement",
            title: "Task Vim movement",
            rows: [
                row("vimChars", "Move by character", .reference, value: "H/L"),
                row("vimWords", "Move by word", .reference, value: "W / B"),
                row("vimLines", "Line boundaries", .reference, value: "0 / ^ / $"),
                row("vimDoc", "Document boundaries", .reference, value: "gg / G"),
            ]
        ),
        .init(
            id: "taskVimEditing",
            title: "Task Vim editing",
            rows: [
                row("vimDeleteLine", "Delete line", .reference, value: "dd"),
                row("vimYankLine", "Copy line", .reference, value: "yy"),
                row("vimPaste", "Paste clipboard", .reference, value: "p"),
                row("vimChangeWord", "Change inner word", .reference, value: "ciw"),
            ]
        ),
        .init(
            id: "taskVimSearch",
            title: "Task Vim search",
            rows: [
                row("vimSearch", "Search", .reference, value: "/"),
                row("vimSearchNext", "Next result", .reference, value: "n"),
                row("vimSearchPrev", "Previous result", .reference, value: "N"),
                row("vimSubstitute", "Replace all", .reference, value: ":%s/a/b/g"),
            ]
        ),
        .init(
            id: "taskTags",
            title: "Task tags",
            rows: [
                row("tagEnter", "Enter tags from task end", .reference, value: "Right"),
                row("tagMove", "Move between tags", .reference, value: "Left / Right"),
                row("tagDelete", "Delete tag", .reference, value: "Backspace"),
                row("tagReturn", "Return to task", .reference, value: "Left on first"),
            ]
        ),
        .init(
            id: "moveMode",
            title: "Move mode",
            rows: [
                row("moveRange", "Range select", .reference, value: "Shift+J/K"),
                row("moveSingle", "Add one item", .reference, value: "Cmd+J/K"),
                row("moveReorder", "Reorder selection", .reference, value: "J/K"),
                row("moveAdjacent", "Move to adjacent tab", .reference, value: "H/L or Left/Right"),
                row("moveDelete", "Delete selected tasks", .reference, value: "D"),
            ]
        ),
    ]
}()

let navigationSettingsRows = navigationSettingsSections.flatMap(\.rows)

func moveSettingsTab(current: NotaApplicationModel.SettingsTab, offset: Int) -> NotaApplicationModel.SettingsTab {
    let tabs = NotaApplicationModel.SettingsTab.allCases
    guard let currentIndex = tabs.firstIndex(of: current) else {
        return tabs[0]
    }

    let nextIndex = (currentIndex + offset + tabs.count) % tabs.count
    return tabs[nextIndex]
}

func moveSettingsFocus(currentIndex: Int, offset: Int, itemCount: Int) -> Int {
    guard itemCount > 0 else {
        return 0
    }

    return (currentIndex + offset + itemCount) % itemCount
}
