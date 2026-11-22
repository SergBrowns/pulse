import SwiftData
import SwiftUI

@main
struct PulseApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .preferredColorScheme(appState.preferredColorScheme)
        }
        .modelContainer(for: [TaskItem.self, CalendarMapping.self])
    }
}

