import SwiftUI

struct LinkPopupView: View {
    enum Field {
        case label
        case url
    }

    let theme: AppTheme
    let onSubmit: (String, String) -> Void
    let onCancel: () -> Void

    @State private var label = ""
    @State private var url = ""
    @FocusState private var focusedField: Field?

    var body: some View {
        VStack(spacing: 6) {
            TextField("Label", text: $label)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .label)
                .onSubmit {
                    if url.isEmpty {
                        focusedField = .url
                    } else {
                        submit()
                    }
                }

            TextField("URL", text: $url)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .url)
                .onSubmit {
                    submit()
                }

            HStack {
                Button("Cancel", action: onCancel)
                Spacer()
                Button("Insert", action: submit)
                    .disabled(label.isEmpty || url.isEmpty)
            }
        }
        .padding(8)
        .frame(width: 220)
        .background(theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.border, lineWidth: 1)
        )
        .onAppear {
            focusedField = .label
        }
    }

    private func submit() {
        guard label.isEmpty == false, url.isEmpty == false else {
            return
        }

        onSubmit(label, url)
    }
}
