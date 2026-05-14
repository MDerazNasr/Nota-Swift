import NotaCore
import SwiftUI

struct AppearanceTabView: View {
    @Environment(NotaApplicationModel.self) private var model

    let theme: AppTheme

    private let swatchColumns = Array(repeating: GridItem(.fixed(24), spacing: 8), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            settingsRow(row: appearanceSettingsRows[0]) {
                LazyVGrid(columns: swatchColumns, alignment: .leading, spacing: 8) {
                    ForEach(ThemeCatalog.orderedThemes, id: \.key) { swatchTheme in
                        Button {
                            model.settingsStore.setTheme(swatchTheme.key)
                        } label: {
                            HStack(spacing: 0) {
                                Rectangle().fill(Color(css: swatchTheme.backgroundHex))
                                Rectangle().fill(Color(css: swatchTheme.surfaceHex))
                                Rectangle().fill(Color(css: swatchTheme.accentHex))
                            }
                            .frame(width: 24, height: 24)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        model.settingsStore.settings.theme == swatchTheme.key ? theme.accent : theme.border,
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            settingsRow(row: appearanceSettingsRows[1]) {
                Picker("", selection: Binding(
                    get: { model.settingsStore.settings.font },
                    set: { model.settingsStore.setFont($0) }
                )) {
                    ForEach(FontOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            sliderRow(
                row: appearanceSettingsRows[2],
                value: model.settingsStore.settings.fontSize,
                range: 10...20
            ) {
                model.settingsStore.setFontSize($0)
            }

            sliderRow(
                row: appearanceSettingsRows[3],
                value: model.settingsStore.settings.borderRadius,
                range: 0...12
            ) {
                model.settingsStore.setBorderRadius($0)
            }

            sliderRow(
                row: appearanceSettingsRows[4],
                value: model.settingsStore.settings.itemLimit,
                range: 5...50
            ) {
                model.settingsStore.setItemLimit($0)
            }
        }
    }

    private func settingsRow<Content: View>(
        row: SettingsRowDescriptor,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Text(row.title)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(theme.textPrimary)
                .frame(width: 88, alignment: .leading)

            content()

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(minHeight: 40)
        .background(model.settingsFocusIndex == row.index ? theme.accentMuted : .clear)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.border)
                .frame(height: 1)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            model.setSettingsFocusIndex(row.index)
        }
        .id(row.index)
    }

    private func sliderRow(
        row: SettingsRowDescriptor,
        value: Int,
        range: ClosedRange<Int>,
        onChange: @escaping (Int) -> Void
    ) -> some View {
        settingsRow(row: row) {
            HStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: { Double(value) },
                        set: { onChange(Int($0)) }
                    ),
                    in: Double(range.lowerBound)...Double(range.upperBound),
                    step: 1
                )

                Text("\(value)")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(theme.textSecondary)
                    .frame(width: 28, alignment: .trailing)
            }
        }
    }
}
