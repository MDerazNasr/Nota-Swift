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
    @State private var monitor: Any?

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
            installMonitor()
        }
        .onDisappear {
            removeMonitor()
        }
    }

    private func submit() {
        guard label.isEmpty == false, url.isEmpty == false else {
            return
        }

        onSubmit(label, url)
    }

    private func installMonitor() {
        removeMonitor()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            switch event.keyCode {
            case 53:
                onCancel()
                return nil
            case 48:
                cycleField(backward: event.modifierFlags.contains(.shift))
                return nil
            case 36, 76:
                submit()
                return nil
            default:
                break
            }

            guard let characters = event.charactersIgnoringModifiers else {
                return event
            }

            if characters == "n", focusedField == .label, label.isEmpty {
                focusedField = .url
                return nil
            }

            if characters == "N", focusedField == .url, url.isEmpty {
                focusedField = .label
                return nil
            }

            return event
        }
    }

    private func cycleField(backward: Bool) {
        if backward {
            focusedField = .label
        } else {
            focusedField = .url
        }
    }

    private func removeMonitor() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
