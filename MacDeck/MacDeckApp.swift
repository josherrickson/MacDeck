import SwiftUI

@main
struct MacDeckApp: App {
    var body: some Scene {
        MenuBarExtra("CardDrawer", systemImage: "rectangle.stack") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
