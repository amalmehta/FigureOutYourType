import SwiftUI

@main
struct FigureOutYourTypeApp: App {
    @State private var model = AppModel()

    init() {
        // Launched as a bare binary (swift run), make it a regular foreground app.
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        Window("Figure Out Your Type", id: "main") {
            ContentView()
                .environment(model)
                .frame(minWidth: 720, minHeight: 520)
        }
        .defaultSize(width: 980, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Start Over") { model.startOver() }
                    .keyboardShortcut("n")
            }
        }

        Settings {
            SettingsView()
        }
    }
}
