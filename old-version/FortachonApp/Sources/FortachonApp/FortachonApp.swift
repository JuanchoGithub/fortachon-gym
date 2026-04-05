import SwiftUI
import SwiftData
import FortachonCore

#if os(iOS)
@main
struct FortachonApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(try! makeInMemoryContainer())
        }
    }
}
#endif
