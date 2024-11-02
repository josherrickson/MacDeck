import SwiftUI

@main
struct MacDeckApp: App {
    var body: some Scene {
        MenuBarExtra("MacDeck", systemImage: "rectangle.stack") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
