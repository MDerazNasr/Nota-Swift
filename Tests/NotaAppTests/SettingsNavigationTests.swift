import Testing
@testable import NotaApp

struct SettingsNavigationTests {
    @Test
    func settingsTabMovementWraps() {
        #expect(moveSettingsTab(current: .appearance, offset: 1) == .navigation)
        #expect(moveSettingsTab(current: .navigation, offset: 1) == .about)
        #expect(moveSettingsTab(current: .about, offset: 1) == .appearance)
        #expect(moveSettingsTab(current: .appearance, offset: -1) == .about)
    }

    @Test
    func settingsFocusMovementWraps() {
        #expect(moveSettingsFocus(currentIndex: 0, offset: 1, itemCount: 3) == 1)
        #expect(moveSettingsFocus(currentIndex: 2, offset: 1, itemCount: 3) == 0)
        #expect(moveSettingsFocus(currentIndex: 0, offset: -1, itemCount: 3) == 2)
        #expect(moveSettingsFocus(currentIndex: 4, offset: 1, itemCount: 0) == 0)
    }

    @Test
    func navigationRowsCoverBehaviorHotkeysAndReferenceSections() {
        #expect(appearanceSettingsRows.count == 5)
        #expect(navigationSettingsSections.first?.title == "Behavior")
        #expect(navigationSettingsSections.last?.title == "Move mode")
        #expect(navigationSettingsRows.count == 55)
    }
}
