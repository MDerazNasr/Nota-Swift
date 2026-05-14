import AppKit
import NotaCore
import SwiftUI

struct NavigationTabView: View {
    @Environment(NotaApplicationModel.self) private var model

    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(navigationSettingsSections) { section in
                VStack(alignment: .leading, spacing: 4) {
                    Text(section.title)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(theme.textMuted)
                        .padding(.top, 8)

                    ForEach(section.rows) { row in
                        switch row.kind {
                        case let .toggle(key):
                            toggleRow(row: row, key: key)
                        case let .hotkey(key):
                            ShortcutCaptureRow(row: row, captureKey: key, theme: theme)
                        case .reference:
                            referenceRow(row: row)
                        case .theme, .font, .fontSize, .borderRadius, .itemLimit:
                            EmptyView()
                        }
                    }
                }
            }
        }
    }

    private func toggleRow(row: SettingsRowDescriptor, key: SettingsBehaviorKey) -> some View {
        HStack(spacing: 8) {
            Text(row.title)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(theme.textPrimary)

            Spacer()

            Toggle("", isOn: binding(for: key))
                .labelsHidden()
                .toggleStyle(.switch)
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

    private func referenceRow(row: SettingsRowDescriptor) -> some View {
        HStack(spacing: 8) {
            Text(row.title)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(theme.textPrimary)

            Spacer()

            Text(row.value ?? "")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(theme.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(theme.background)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.border, lineWidth: 1)
                )
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

    private func binding(for key: SettingsBehaviorKey) -> Binding<Bool> {
        Binding(
            get: {
                switch key {
                case .openOnStartup:
                    model.settingsStore.settings.openOnStartup
                case .showInDock:
                    model.settingsStore.settings.showInDock
                case .showInMenuBar:
                    model.settingsStore.settings.showInMenuBar
                }
            },
            set: { enabled in
                switch key {
                case .openOnStartup:
                    model.setOpenOnStartup(enabled)
                case .showInDock:
                    model.setShowInDock(enabled)
                case .showInMenuBar:
                    model.setShowInMenuBar(enabled)
                }
            }
        )
    }
}

private struct ShortcutCaptureRow: View {
    @Environment(NotaApplicationModel.self) private var model

    let row: SettingsRowDescriptor
    let captureKey: SettingsShortcutCaptureKey
    let theme: AppTheme

    @State private var monitor: Any?

    var body: some View {
        HStack(spacing: 8) {
            Text(row.title)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(theme.textPrimary)

            Spacer()

            Button(isCapturing ? "Press keys" : ShortcutFormatter.display(currentValue)) {
                model.settingsCaptureKey = captureKey
                model.setSettingsFocusIndex(row.index)
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .regular, design: .monospaced))
            .foregroundStyle(isCapturing ? theme.textPrimary : theme.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isCapturing ? theme.surfaceHover : theme.background)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isCapturing ? theme.accent : theme.border, lineWidth: 1)
            )
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
        .onAppear {
            if isCapturing {
                installMonitor()
            }
        }
        .onChange(of: isCapturing) { _, active in
            active ? installMonitor() : removeMonitor()
        }
        .onDisappear {
            removeMonitor()
        }
    }

    private var isCapturing: Bool {
        model.settingsCaptureKey == captureKey
    }

    private var currentValue: String {
        captureKey.value(from: model.settingsStore.settings.shortcuts)
    }

    private func installMonitor() {
        removeMonitor()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard isCapturing else {
                return event
            }

            if event.keyCode == 53 {
                model.settingsCaptureKey = nil
                return nil
            }

            if event.keyCode == 51 || event.keyCode == 117 {
                saveShortcut("")
                return nil
            }

            let next = EventShortcutFormatter.format(event)
            guard next.isEmpty == false else {
                return nil
            }

            saveShortcut(next)
            return nil
        }
    }

    private func saveShortcut(_ value: String) {
        model.updateShortcut { shortcuts in
            captureKey.assign(value, to: &shortcuts)
        }
        model.settingsCaptureKey = nil
    }

    private func removeMonitor() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
