import NotaCore
import SwiftUI

struct SlashMenuView: View {
    let items: [SlashMenuItem]
    let theme: AppTheme
    let onSelect: (SlashMenuItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                Button {
                    onSelect(item)
                } label: {
                    HStack(spacing: 8) {
                        Text(label(for: item))
                        Spacer(minLength: 8)
                        Text(description(for: item))
                            .foregroundStyle(theme.textMuted)
                    }
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .foregroundStyle(theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(4)
        .frame(width: 220)
        .background(theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.border, lineWidth: 1)
        )
    }

    private func label(for item: SlashMenuItem) -> String {
        switch item {
        case let .command(_, _, label, _):
            label
        case let .tag(_, _, label, _):
            label
        case let .createTag(_, _, label, _):
            label
        }
    }

    private func description(for item: SlashMenuItem) -> String {
        switch item {
        case let .command(_, _, _, description):
            description
        case let .tag(_, _, _, description):
            description
        case let .createTag(_, _, _, description):
            description
        }
    }
}
