import SwiftUI
import FortachonCore

struct TrainView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Quick Start") {
                    Text("Start a new workout")
                }
                Section("Your Routines") {
                    Text("No routines yet")
                }
            }
            .navigationTitle("Train")
        }
    }
}

struct HistoryView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Workout History") {
                    Text("No workouts logged yet")
                }
            }
            .navigationTitle("History")
        }
    }
}

struct ExercisesView: View {
    @State private var search = ""
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(BodyPart.allCases, id: \.self) { part in
                        ExerciseGroupCard(bodyPart: part)
                    }
                }
                .padding()
            }
            .navigationTitle("Exercises")
            .searchable(text: $search)
        }
    }
}

struct ExerciseGroupCard: View {
    let bodyPart: BodyPart
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(bodyPart.rawValue)
                .font(.headline)
            Text("Tap to browse exercises")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.quinary, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct SupplementsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Today") {
                    Text("Set up your supplement plan")
                }
            }
            .navigationTitle("Supplements")
        }
    }
}

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Profile") {
                    Text("Complete your profile")
                }
                Section("Settings") {
                    Text("Units (kg/lbs)")
                    Text("Notifications")
                    Text("iCloud Sync")
                }
                Section("Data") {
                    Text("Export backup")
                    Text("Import backup")
                }
            }
            .navigationTitle("Profile")
        }
    }
}
