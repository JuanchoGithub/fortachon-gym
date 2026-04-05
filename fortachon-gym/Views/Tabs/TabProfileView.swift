import SwiftUI
import SwiftData
import FortachonCore

struct TabProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [UserPreferencesM]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    
    var prefs: UserPreferencesM? { preferences.first }
    
    var body: some View {
        NavigationStack {
            List {
                // App Info
                Section("Fortachon") {
                    HStack {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.largeTitle)
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading) {
                            Text("Fortachon Gym")
                                .font(.headline)
                            Text("Version 1.0")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Preferences
                if let prefs = prefs {
                    Section("Preferences") {
                        Picker("Weight Unit", selection: prefs.getBinding(\.weightUnitStr)) {
                            Text("Kilograms (kg)").tag("kg")
                            Text("Pounds (lbs)").tag("lbs")
                        }
                        .onChange(of: prefs.weightUnitStr) { _, _ in
                            try? modelContext.save()
                        }
                        
                        Picker("Main Goal", selection: prefs.getBinding(\.mainGoalStr)) {
                            Text("Muscle Building").tag("muscle")
                            Text("Strength").tag("strength")
                            Text("General Fitness").tag("fitness")
                        }
                        .onChange(of: prefs.mainGoalStr) { _, _ in
                            try? modelContext.save()
                        }
                    }
                    
                    Section("Data") {
                        Button(role: .destructive) {
                            // Reset onboarding
                            hasCompletedOnboarding = false
                        } label: {
                            Label("Reset Onboarding", systemImage: "arrow.clockwise")
                        }
                    }
                }
                
                // Stats
                Section("Quick Stats") {
                    VStack(alignment: .leading, spacing: 12) {
                        ProfileStatRow(icon: "calendar", title: "Workouts logged", value: "0")
                        ProfileStatRow(icon: "flame", title: "Calories burned", value: "0")
                        ProfileStatRow(icon: "clock", title: "Training time", value: "0h")
                    }
                    .padding(.vertical, 8)
                }
                
                // Links
                Section("Resources") {
                    Link(destination: URL(string: "https://github.com/JuanchoGithub/fortachon-gym")!) {
                        Label("GitHub", systemImage: "link")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Profile Stats Row

struct ProfileStatRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.headline)
        }
    }
}

// MARK: - Extension for SwiftData binding

extension UserPreferencesM {
    func getBinding<T>(_ keyPath: ReferenceWritableKeyPath<UserPreferencesM, T>) -> Binding<T> {
        Binding(
            get: { self[keyPath: keyPath] },
            set: { self[keyPath: keyPath] = $0 }
        )
    }
}

#Preview {
    TabProfileView()
}