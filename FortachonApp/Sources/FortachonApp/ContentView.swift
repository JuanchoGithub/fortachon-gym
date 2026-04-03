import SwiftUI
import FortachonCore

struct ContentView: View {
    @State private var selectedTab: AppTab = .train

    enum AppTab: String, CaseIterable, Identifiable {
        case train, history, exercises, supplements, profile
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .train: return "figure.strengthtraining.traditional"
            case .history: return "clock.arrow.circlepath"
            case .exercises: return "dumbbell"
            case .supplements: return "pill"
            case .profile: return "person.circle"
            }
        }
        var label: String {
            switch self {
            case .train: return "Train"
            case .history: return "History"
            case .exercises: return "Exercises"
            case .supplements: return "Supplements"
            case .profile: return "Profile"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TrainView().tabItem {
                Label(AppTab.train.label, systemImage: AppTab.train.icon)
            }.tag(AppTab.train)

            HistoryView().tabItem {
                Label(AppTab.history.label, systemImage: AppTab.history.icon)
            }.tag(AppTab.history)

            ExercisesView().tabItem {
                Label(AppTab.exercises.label, systemImage: AppTab.exercises.icon)
            }.tag(AppTab.exercises)

            SupplementsView().tabItem {
                Label(AppTab.supplements.label, systemImage: AppTab.supplements.icon)
            }.tag(AppTab.supplements)

            ProfileView().tabItem {
                Label(AppTab.profile.label, systemImage: AppTab.profile.icon)
            }.tag(AppTab.profile)
        }
    }
}
