import SwiftUI

struct RootView: View {
    @Bindable var model: NotaApplicationModel

    var body: some View {
        let theme = AppTheme.from(settings: model.settingsStore.settings)

        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                TitleBarView(theme: theme)
                TabBarView(theme: theme)
                ItemListView(theme: theme)
            }
            .background(theme.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.border, lineWidth: 1)
            )

            SettingsPanelView(theme: theme)
        }
        .frame(minWidth: WindowGeometry.minWidth, minHeight: WindowGeometry.minHeight)
        .background(theme.background)
        .font(.custom(model.settingsStore.settings.font.rawValue, size: CGFloat(model.settingsStore.settings.fontSize)))
    }
}
