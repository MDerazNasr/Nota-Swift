import AppKit
import SwiftUI

struct AboutTabView: View {
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("nota")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(theme.textPrimary)

            Text("Version 0.1.0")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(theme.textSecondary)

            Text("A keyboard-first to-do list for developers. Made for simplicity and productivity.")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(theme.textSecondary)

            Text("Feel free to make any PRs/ suggestions for new features!")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(theme.textSecondary)

            HStack(spacing: 8) {
                actionButton("Repository", url: "https://github.com/MDerazNasr/Nota")
                actionButton("LinkedIn", url: "https://www.linkedin.com/in/mohamed-deraz-nasr-21825b203/")
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private func actionButton(_ title: String, url: String) -> some View {
        Button(title) {
            guard let target = URL(string: url) else {
                return
            }

            NSWorkspace.shared.open(target)
        }
        .buttonStyle(.plain)
        .font(.system(size: 12, weight: .regular, design: .monospaced))
        .foregroundStyle(theme.textPrimary)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.border, lineWidth: 1)
        )
    }
}
