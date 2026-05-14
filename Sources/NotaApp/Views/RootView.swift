import SwiftUI

struct RootView: View {
    @Bindable var model: NotaApplicationModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("nota")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                Spacer()
                Text("\(model.notesStore.tabs.count)")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
            }
            .padding(.horizontal, 12)
            .frame(height: 36)

            Divider()

            VStack(spacing: 8) {
                Text(model.notesStore.activeTab?.title ?? "Untitled")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                Text("Clean rebuild in progress")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: WindowGeometry.minWidth, minHeight: WindowGeometry.minHeight)
        .background(Color.black.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
    }
}
