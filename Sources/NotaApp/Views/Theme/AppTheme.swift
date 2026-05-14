import NotaCore
import SwiftUI

struct AppTheme {
    let background: Color
    let surface: Color
    let surfaceHover: Color
    let border: Color
    let textPrimary: Color
    let textSecondary: Color
    let textMuted: Color
    let accent: Color
    let accentMuted: Color
    let doneOpacity: Double

    static func from(settings: NotaCore.Settings) -> AppTheme {
        let theme = ThemeCatalog.theme(for: settings.theme)
        return AppTheme(
            background: Color(css: theme.backgroundHex),
            surface: Color(css: theme.surfaceHex),
            surfaceHover: Color(css: theme.surfaceHoverHex),
            border: Color(css: theme.borderHex),
            textPrimary: Color(css: theme.textPrimaryHex),
            textSecondary: Color(css: theme.textSecondaryHex),
            textMuted: Color(css: theme.textMutedHex),
            accent: Color(css: theme.accentHex),
            accentMuted: Color(css: theme.accentMutedHex),
            doneOpacity: theme.doneOpacity
        )
    }
}

extension Color {
    init(css: String) {
        if css.hasPrefix("rgb("), let color = Self.parseRGB(css) {
            self = color
            return
        }

        let hex = css.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let value = UInt64(hex, radix: 16) ?? 0
        let red: Double
        let green: Double
        let blue: Double
        let opacity: Double

        switch hex.count {
        case 6:
            red = Double((value >> 16) & 0xFF) / 255
            green = Double((value >> 8) & 0xFF) / 255
            blue = Double(value & 0xFF) / 255
            opacity = 1
        case 8:
            red = Double((value >> 24) & 0xFF) / 255
            green = Double((value >> 16) & 0xFF) / 255
            blue = Double((value >> 8) & 0xFF) / 255
            opacity = Double(value & 0xFF) / 255
        default:
            red = 0
            green = 0
            blue = 0
            opacity = 1
        }

        self = Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }

    private static func parseRGB(_ css: String) -> Color? {
        let values = css
            .replacingOccurrences(of: "rgb(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "/", with: ",")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard values.count == 4,
              let red = Double(values[0]),
              let green = Double(values[1]),
              let blue = Double(values[2]),
              let opacityPercent = Double(values[3].replacingOccurrences(of: "%", with: "")) else {
            return nil
        }

        return Color(
            .sRGB,
            red: red / 255,
            green: green / 255,
            blue: blue / 255,
            opacity: opacityPercent / 100
        )
    }
}
