import SwiftUI
import SwiftData
import FortachonCore

@main
struct FortachonApp: App {
    @ApplicationStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(Self.makeContainer())
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .active {
                        print("App became active")
                    }
                }
        }
    }
    
    /// Creates a persistent ModelContainer with all SwiftData models
    static func makeContainer() -> ModelContainer {
        do {
            let schema = Schema([
                ExerciseM.self,
                PerformedSetM.self,
                WorkoutExerciseM.self,
                SupersetM.self,
                WorkoutSessionM.self,
                RoutineM.self,
                UserPreferencesM.self,
                SupplementLogM.self
            ])
            
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            
            let container = try ModelContainer(
                for: schema,
                configurations: [config]
            )
            
            // Seed initial data if needed
            let context = ModelContext(container)
            if try! context.fetch(FetchDescriptor<RoutineM>()).isEmpty {
                ExerciseSeeder.shared.seed(context: context)
            }
            
            return container
        } catch {
            // Fall back to in-memory if persistent store fails
            return try! makeInMemoryContainer()
        }
    }
}