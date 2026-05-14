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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
}
