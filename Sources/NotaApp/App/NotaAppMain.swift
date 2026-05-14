import SwiftUI

@main
struct NotaAppMain: App {
    @State private var model = NotaApplicationModel()

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
                .task {
                    await model.start()
                }
                .background(
                    WindowAccessor { window in
                        model.windowCoordinator.configure(window: window, settingsStore: model.settingsStore)
                    }
                )
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: WindowGeometry.defaultWidth, height: WindowGeometry.defaultHeight)
        .environment(model)
    }
}
