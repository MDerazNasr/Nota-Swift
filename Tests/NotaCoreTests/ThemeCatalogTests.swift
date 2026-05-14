import Foundation
import Testing
@testable import NotaCore

struct ThemeCatalogTests {
    @Test
    func catalogContainsAllShippedThemes() {
        #expect(ThemeCatalog.orderedThemes.count == 26)
        #expect(ThemeCatalog.contains("dark-zinc"))
        #expect(ThemeCatalog.contains("github-dark"))
        #expect(ThemeCatalog.tagColors.count == 10)
    }

    @Test
    func invalidThemeFallsBackToDefault() {
        let normalized = SettingsNormalizer.normalize(
            settings: Settings(
                theme: "missing-theme",
                font: .jetBrainsMono,
                fontSize: 13,
                borderRadius: 8,
                itemLimit: 15,
                openOnStartup: false,
                showInDock: true,
                showInMenuBar: false,
                shortcuts: AppDefaults.defaultShortcuts
            )
        )

        #expect(normalized.theme == ThemeCatalog.defaultThemeKey)
    }
}
