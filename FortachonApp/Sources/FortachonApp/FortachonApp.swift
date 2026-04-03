import SwiftUI
import SwiftData
import FortachonCore

@main
struct FortachonApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(makeSharedContainer())
        }
    }

    private func makeSharedContainer() -> ModelContainer {
        do {
            return try makeInMemoryContainer()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
