import Foundation

public enum FontOption: String, Codable, CaseIterable, Equatable, Sendable {
    case jetBrainsMono = "JetBrains Mono"
    case sfMono = "SF Mono"
    case ibmPlexMono = "IBM Plex Mono"
    case geistMono = "Geist Mono"
    case firaCode = "Fira Code"
    case iosevka = "Iosevka"
    case inconsolata = "Inconsolata"
    case spaceMono = "Space Mono"
    case berkeleyMono = "Berkeley Mono"
}

public struct ShortcutMap: Codable, Equatable, Sendable {
    public var toggleWindow: String
    public var newTab: String
    public var deleteTab: String
    public var openSettings: String
    public var checkItem: String
    public var renameTab: String
    public var moveTabLeft: String
    public var moveTabRight: String
    public var createItemBelow: String
    public var createItemAbove: String
    public var editItem: String
    public var deleteItem: String
    public var enterMoveMode: String
    public var undo: String
    public var openItemLink: String
    public var sortByTag: String

    public init(
        toggleWindow: String,
        newTab: String,
        deleteTab: String,
        openSettings: String,
        checkItem: String,
        renameTab: String,
        moveTabLeft: String,
        moveTabRight: String,
        createItemBelow: String,
        createItemAbove: String,
        editItem: String,
        deleteItem: String,
        enterMoveMode: String,
        undo: String,
        openItemLink: String,
        sortByTag: String
    ) {
        self.toggleWindow = toggleWindow
        self.newTab = newTab
        self.deleteTab = deleteTab
        self.openSettings = openSettings
        self.checkItem = checkItem
        self.renameTab = renameTab
        self.moveTabLeft = moveTabLeft
        self.moveTabRight = moveTabRight
        self.createItemBelow = createItemBelow
        self.createItemAbove = createItemAbove
        self.editItem = editItem
        self.deleteItem = deleteItem
        self.enterMoveMode = enterMoveMode
        self.undo = undo
        self.openItemLink = openItemLink
        self.sortByTag = sortByTag
    }
}

public struct WindowPosition: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public struct WindowSize: Codable, Equatable, Sendable {
    public var width: Double
    public var height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
}

public struct Settings: Codable, Equatable, Sendable {
    public var theme: String
    public var font: FontOption
    public var fontSize: Int
    public var borderRadius: Int
    public var itemLimit: Int
    public var openOnStartup: Bool
    public var showInDock: Bool
    public var showInMenuBar: Bool
    public var shortcuts: ShortcutMap
    public var windowPosition: WindowPosition?
    public var windowSize: WindowSize?

    public init(
        theme: String,
        font: FontOption,
        fontSize: Int,
        borderRadius: Int,
        itemLimit: Int,
        openOnStartup: Bool,
        showInDock: Bool,
        showInMenuBar: Bool,
        shortcuts: ShortcutMap,
        windowPosition: WindowPosition? = nil,
        windowSize: WindowSize? = nil
    ) {
        self.theme = theme
        self.font = font
        self.fontSize = fontSize
        self.borderRadius = borderRadius
        self.itemLimit = itemLimit
        self.openOnStartup = openOnStartup
        self.showInDock = showInDock
        self.showInMenuBar = showInMenuBar
        self.shortcuts = shortcuts
        self.windowPosition = windowPosition
        self.windowSize = windowSize
    }
}
