import SwiftUI
import FortachonCore

struct ContentView: View {
    @State private var selectedTab: AppTab = .train
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    enum AppTab: Int, CaseIterable {
        case train, history, exercises, supplements, profile
        
        var title: String {
            switch self {
            case .train: return "Train"
            case .history: return "History"
            case .exercises: return "Exercises"
            case .supplements: return "Supplements"
            case .profile: return "Profile"
            }
        }
        
        var icon: String {
            switch self {
            case .train: return "figure.strengthtraining.traditional"
            case .history: return "clock.arrow.circlepath"
            case .exercises: return "dumbbell"
            case .supplements: return "pill"
            case .profile: return "person.circle"
            }
        }
        
        var tag: Int { return self.rawValue }
    }
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView(completedOnboarding: $hasCompletedOnboarding)
            } else {
                TabView(selection: $selectedTab) {
                    TabTrainView()
                        .tabItem {
                            Label(AppTab.train.title, systemImage: AppTab.train.icon)
                        }
                        .tag(AppTab.train.tag)
                    
                    TabHistoryView()
                        .tabItem {
                            Label(AppTab.history.title, systemImage: AppTab.history.icon)
                        }
                        .tag(AppTab.history.tag)
                    
                    TabExercisesView()
                        .tabItem {
                            Label(AppTab.exercises.title, systemImage: AppTab.exercises.icon)
                        }
                        .tag(AppTab.exercises.tag)
                    
                    TabSupplementsView()
                        .tabItem {
                            Label(AppTab.supplements.title, systemImage: AppTab.supplements.icon)
                        }
                        .tag(AppTab.supplements.tag)
                    
                    TabProfileView()
                        .tabItem {
                            Label(AppTab.profile.title, systemImage: AppTab.profile.icon)
                        }
                        .tag(AppTab.profile.tag)
                }
                .tint(.blue)
            }
        }
    }
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @Binding var completedOnboarding: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                
                Text("Welcome to Fortachon")
                    .font(.largeTitle.bold())
                
                Text("Your personal strength training companion")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 16) {
                    OnboardingFeatureRow(icon: "dumbbell", title: "Track Workouts", desc: "Log your sets, reps, and weight")
                    OnboardingFeatureRow(icon: "chart.line.uptrend.xyaxis", title: "See Progress", desc: "Visualize your strength gains")
                    OnboardingFeatureRow(icon: "brain", title: "Smart Coaching", desc: "Get personalized recommendations")
                }
                .padding(.horizontal)
                .padding(.vertical, 20)
                
                Spacer()
                
                Button {
                    completedOnboarding = true
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingFeatureRow: View {
    let icon: String
    let title: String
    let desc: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(desc).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
}