import SwiftUI

@main
struct CellaApp: App {
    var body: some Scene {
        MenuBarExtra("Cella", systemImage: "battery.100") {
            Text("Hello, Cella! 🔋")
                .padding()
        }
        .menuBarExtraStyle(.window)
    }
}
