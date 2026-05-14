import SwiftUI

struct SettingsPanelView: View {
    @Environment(NotaApplicationModel.self) private var model

    let theme: AppTheme

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("Settings")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(theme.textPrimary)

                Spacer()

                Button {
                    model.closeSettings()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(theme.textSecondary)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .frame(height: 36)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(theme.border)
                    .frame(height: 1)
            }

            HStack(spacing: 4) {
                SettingsTabButton(tab: .appearance, title: "Appearance", theme: theme)
                SettingsTabButton(tab: .navigation, title: "Navigation", theme: theme)
                SettingsTabButton(tab: .about, title: "About", theme: theme)
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 8)

            ScrollView(.vertical, showsIndicators: true) {
                Group {
                    switch model.settingsTab {
                    case .appearance:
                        AppearanceTabView(theme: theme)
                    case .navigation:
                        NavigationTabView(theme: theme)
                    case .about:
                        AboutTabView(theme: theme)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            }
            .scrollContentBackground(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(theme.surface)
        .offset(x: model.settingsOpen ? 0 : 420)
        .opacity(model.settingsOpen ? 1 : 0.001)
        .allowsHitTesting(model.settingsOpen)
        .animation(.easeInOut(duration: 0.2), value: model.settingsOpen)
    }
}

private struct SettingsTabButton: View {
    @Environment(NotaApplicationModel.self) private var model

    let tab: NotaApplicationModel.SettingsTab
    let title: String
    let theme: AppTheme

    var body: some View {
        Button {
            model.settingsTab = tab
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(model.settingsTab == tab ? theme.textPrimary : theme.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 28)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(model.settingsTab == tab ? theme.accent : theme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
