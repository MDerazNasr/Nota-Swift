import Foundation

public struct ThemeDefinition: Equatable, Sendable {
    public var key: String
    public var name: String
    public var backgroundHex: String
    public var surfaceHex: String
    public var surfaceHoverHex: String
    public var borderHex: String
    public var textPrimaryHex: String
    public var textSecondaryHex: String
    public var textMutedHex: String
    public var accentHex: String
    public var accentMutedHex: String
    public var doneOpacity: Double

    public init(
        key: String,
        name: String,
        backgroundHex: String,
        surfaceHex: String,
        surfaceHoverHex: String,
        borderHex: String,
        textPrimaryHex: String,
        textSecondaryHex: String,
        textMutedHex: String,
        accentHex: String,
        accentMutedHex: String,
        doneOpacity: Double
    ) {
        self.key = key
        self.name = name
        self.backgroundHex = backgroundHex
        self.surfaceHex = surfaceHex
        self.surfaceHoverHex = surfaceHoverHex
        self.borderHex = borderHex
        self.textPrimaryHex = textPrimaryHex
        self.textSecondaryHex = textSecondaryHex
        self.textMutedHex = textMutedHex
        self.accentHex = accentHex
        self.accentMutedHex = accentMutedHex
        self.doneOpacity = doneOpacity
    }
}

public enum ThemeCatalog {
    public static let defaultThemeKey = "dark-zinc"

    public static let orderedThemes: [ThemeDefinition] = [
        .init(key: "dark-zinc", name: "Dark", backgroundHex: "#09090b", surfaceHex: "#18181b", surfaceHoverHex: "#27272a", borderHex: "#3f3f46", textPrimaryHex: "#f4f4f5", textSecondaryHex: "#a1a1aa", textMutedHex: "#71717a", accentHex: "#4F8EF7", accentMutedHex: "rgb(79 142 247 / 30%)", doneOpacity: 0.45),
        .init(key: "light", name: "Light", backgroundHex: "#ffffff", surfaceHex: "#f8fafc", surfaceHoverHex: "#e2e8f0", borderHex: "#cbd5e1", textPrimaryHex: "#0f172a", textSecondaryHex: "#475569", textMutedHex: "#64748b", accentHex: "#2563EB", accentMutedHex: "rgb(37 99 235 / 30%)", doneOpacity: 0.45),
        .init(key: "paper-trail", name: "Paper Trail", backgroundHex: "#fbf7ef", surfaceHex: "#f1eadf", surfaceHoverHex: "#e6d9c8", borderHex: "#c9b8a3", textPrimaryHex: "#211f1c", textSecondaryHex: "#5b5146", textMutedHex: "#8a7b69", accentHex: "#b45309", accentMutedHex: "rgb(180 83 9 / 24%)", doneOpacity: 0.48),
        .init(key: "blueprint", name: "Blueprint", backgroundHex: "#eef6ff", surfaceHex: "#dbeafe", surfaceHoverHex: "#bfdbfe", borderHex: "#93c5fd", textPrimaryHex: "#10233f", textSecondaryHex: "#315b8d", textMutedHex: "#64748b", accentHex: "#dc2626", accentMutedHex: "rgb(220 38 38 / 20%)", doneOpacity: 0.46),
        .init(key: "matcha", name: "Matcha", backgroundHex: "#f4f7ed", surfaceHex: "#e5ead8", surfaceHoverHex: "#d4dec2", borderHex: "#a8b58e", textPrimaryHex: "#1f2a1d", textSecondaryHex: "#526641", textMutedHex: "#7b856d", accentHex: "#0f766e", accentMutedHex: "rgb(15 118 110 / 22%)", doneOpacity: 0.46),
        .init(key: "lilac-light", name: "Lilac Light", backgroundHex: "#faf5ff", surfaceHex: "#f3e8ff", surfaceHoverHex: "#e9d5ff", borderHex: "#c4b5fd", textPrimaryHex: "#2e1065", textSecondaryHex: "#6d28d9", textMutedHex: "#8b5cf6", accentHex: "#db2777", accentMutedHex: "rgb(219 39 119 / 22%)", doneOpacity: 0.46),
        .init(key: "sunrise", name: "Sunrise", backgroundHex: "#fff7ed", surfaceHex: "#ffedd5", surfaceHoverHex: "#fed7aa", borderHex: "#fdba74", textPrimaryHex: "#32170c", textSecondaryHex: "#9a3412", textMutedHex: "#c2410c", accentHex: "#7c3aed", accentMutedHex: "rgb(124 58 237 / 20%)", doneOpacity: 0.47),
        .init(key: "candy-terminal", name: "Candy Terminal", backgroundHex: "#12071f", surfaceHex: "#21112f", surfaceHoverHex: "#321845", borderHex: "#653780", textPrimaryHex: "#ffe4f3", textSecondaryHex: "#a7f3d0", textMutedHex: "#d8b4fe", accentHex: "#fb7185", accentMutedHex: "rgb(251 113 133 / 28%)", doneOpacity: 0.46),
        .init(key: "acid-graphite", name: "Acid Graphite", backgroundHex: "#111315", surfaceHex: "#1c1f22", surfaceHoverHex: "#292d31", borderHex: "#464d53", textPrimaryHex: "#f2f7f2", textSecondaryHex: "#b5c2b8", textMutedHex: "#7f8b83", accentHex: "#d9f99d", accentMutedHex: "rgb(217 249 157 / 24%)", doneOpacity: 0.45),
        .init(key: "lagoon", name: "Lagoon", backgroundHex: "#061a1f", surfaceHex: "#0b2a31", surfaceHoverHex: "#123842", borderHex: "#27616d", textPrimaryHex: "#e0fbfc", textSecondaryHex: "#98f5e1", textMutedHex: "#70a9a1", accentHex: "#f4d35e", accentMutedHex: "rgb(244 211 94 / 24%)", doneOpacity: 0.45),
        .init(key: "catppuccin-mocha", name: "Catppuccin Mocha", backgroundHex: "#1e1e2e", surfaceHex: "#313244", surfaceHoverHex: "#45475a", borderHex: "#585b70", textPrimaryHex: "#cdd6f4", textSecondaryHex: "#bac2de", textMutedHex: "#7f849c", accentHex: "#cba6f7", accentMutedHex: "rgb(203 166 247 / 30%)", doneOpacity: 0.45),
        .init(key: "dracula", name: "Dracula", backgroundHex: "#282a36", surfaceHex: "#44475a", surfaceHoverHex: "#565a72", borderHex: "#6272a4", textPrimaryHex: "#f8f8f2", textSecondaryHex: "#d7d7d0", textMutedHex: "#a4a5b5", accentHex: "#bd93f9", accentMutedHex: "rgb(189 147 249 / 30%)", doneOpacity: 0.45),
        .init(key: "rose-pine", name: "Rose Pine", backgroundHex: "#191724", surfaceHex: "#1f1d2e", surfaceHoverHex: "#26233a", borderHex: "#403d52", textPrimaryHex: "#e0def4", textSecondaryHex: "#908caa", textMutedHex: "#6e6a86", accentHex: "#ebbcba", accentMutedHex: "rgb(235 188 186 / 30%)", doneOpacity: 0.45),
        .init(key: "tokyo-night", name: "Tokyo Night", backgroundHex: "#16161e", surfaceHex: "#1f2335", surfaceHoverHex: "#292e42", borderHex: "#3b4261", textPrimaryHex: "#c0caf5", textSecondaryHex: "#a9b1d6", textMutedHex: "#565f89", accentHex: "#7aa2f7", accentMutedHex: "rgb(122 162 247 / 30%)", doneOpacity: 0.45),
        .init(key: "solarized-dark", name: "Solarized Dark", backgroundHex: "#002b36", surfaceHex: "#073642", surfaceHoverHex: "#0b4654", borderHex: "#586e75", textPrimaryHex: "#fdf6e3", textSecondaryHex: "#93a1a1", textMutedHex: "#657b83", accentHex: "#2aa198", accentMutedHex: "rgb(42 161 152 / 30%)", doneOpacity: 0.45),
        .init(key: "gruvbox-dark", name: "Gruvbox Dark", backgroundHex: "#1d2021", surfaceHex: "#282828", surfaceHoverHex: "#3c3836", borderHex: "#504945", textPrimaryHex: "#ebdbb2", textSecondaryHex: "#d5c4a1", textMutedHex: "#928374", accentHex: "#83a598", accentMutedHex: "rgb(131 165 152 / 30%)", doneOpacity: 0.45),
        .init(key: "everforest-dark", name: "Everforest Dark", backgroundHex: "#1e2326", surfaceHex: "#272e33", surfaceHoverHex: "#343f44", borderHex: "#4f5b58", textPrimaryHex: "#d3c6aa", textSecondaryHex: "#a7c080", textMutedHex: "#859289", accentHex: "#a7c080", accentMutedHex: "rgb(167 192 128 / 30%)", doneOpacity: 0.45),
        .init(key: "nord-dark", name: "Nord", backgroundHex: "#2e3440", surfaceHex: "#3b4252", surfaceHoverHex: "#434c5e", borderHex: "#4c566a", textPrimaryHex: "#eceff4", textSecondaryHex: "#d8dee9", textMutedHex: "#81a1c1", accentHex: "#88c0d0", accentMutedHex: "rgb(136 192 208 / 30%)", doneOpacity: 0.45),
        .init(key: "one-dark", name: "One Dark", backgroundHex: "#1f2329", surfaceHex: "#282c34", surfaceHoverHex: "#323842", borderHex: "#4b5263", textPrimaryHex: "#abb2bf", textSecondaryHex: "#98c379", textMutedHex: "#5c6370", accentHex: "#61afef", accentMutedHex: "rgb(97 175 239 / 30%)", doneOpacity: 0.45),
        .init(key: "monokai", name: "Monokai", backgroundHex: "#1b1d1e", surfaceHex: "#272822", surfaceHoverHex: "#3e3d32", borderHex: "#5b5a4c", textPrimaryHex: "#f8f8f2", textSecondaryHex: "#cfcfc2", textMutedHex: "#75715e", accentHex: "#a6e22e", accentMutedHex: "rgb(166 226 46 / 28%)", doneOpacity: 0.45),
        .init(key: "kanagawa-wave", name: "Kanagawa", backgroundHex: "#1f1f28", surfaceHex: "#2a2a37", surfaceHoverHex: "#363646", borderHex: "#54546d", textPrimaryHex: "#dcd7ba", textSecondaryHex: "#c8c093", textMutedHex: "#727169", accentHex: "#7e9cd8", accentMutedHex: "rgb(126 156 216 / 30%)", doneOpacity: 0.45),
        .init(key: "ayu-dark", name: "Ayu Dark", backgroundHex: "#0b0e14", surfaceHex: "#11151c", surfaceHoverHex: "#1b2330", borderHex: "#2d3640", textPrimaryHex: "#bfbdb6", textSecondaryHex: "#e6b673", textMutedHex: "#5c6773", accentHex: "#39bae6", accentMutedHex: "rgb(57 186 230 / 30%)", doneOpacity: 0.45),
        .init(key: "night-owl", name: "Night Owl", backgroundHex: "#011627", surfaceHex: "#0b2942", surfaceHoverHex: "#123653", borderHex: "#1d3b53", textPrimaryHex: "#d6deeb", textSecondaryHex: "#82aaff", textMutedHex: "#637777", accentHex: "#addb67", accentMutedHex: "rgb(173 219 103 / 28%)", doneOpacity: 0.45),
        .init(key: "palenight", name: "Palenight", backgroundHex: "#292d3e", surfaceHex: "#30364a", surfaceHoverHex: "#3a4159", borderHex: "#676e95", textPrimaryHex: "#eeffff", textSecondaryHex: "#c3e88d", textMutedHex: "#8796b0", accentHex: "#ffcb6b", accentMutedHex: "rgb(255 203 107 / 28%)", doneOpacity: 0.45),
        .init(key: "github-dark", name: "GitHub Dark", backgroundHex: "#0d1117", surfaceHex: "#161b22", surfaceHoverHex: "#21262d", borderHex: "#30363d", textPrimaryHex: "#e6edf3", textSecondaryHex: "#8b949e", textMutedHex: "#6e7681", accentHex: "#2f81f7", accentMutedHex: "rgb(47 129 247 / 30%)", doneOpacity: 0.45),
        .init(key: "high-contrast", name: "High Contrast", backgroundHex: "#000000", surfaceHex: "#111111", surfaceHoverHex: "#1f1f1f", borderHex: "#5f5f5f", textPrimaryHex: "#ffffff", textSecondaryHex: "#d4d4d4", textMutedHex: "#a3a3a3", accentHex: "#00e5ff", accentMutedHex: "rgb(0 229 255 / 32%)", doneOpacity: 0.5),
    ]

    public static let themes: [String: ThemeDefinition] = Dictionary(
        uniqueKeysWithValues: orderedThemes.map { ($0.key, $0) }
    )

    public static let tagColors = [
        "#4f8ef7",
        "#14b8a6",
        "#22c55e",
        "#eab308",
        "#f97316",
        "#ef4444",
        "#ec4899",
        "#8b5cf6",
        "#06b6d4",
        "#84cc16",
    ]

    public static func contains(_ key: String) -> Bool {
        themes[key] != nil
    }

    public static func theme(for key: String) -> ThemeDefinition {
        themes[key] ?? themes[defaultThemeKey] ?? orderedThemes[0]
    }
}
