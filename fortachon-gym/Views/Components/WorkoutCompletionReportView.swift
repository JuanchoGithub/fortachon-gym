import SwiftUI
import FortachonCore

// MARK: - Workout Completion Report View

struct WorkoutCompletionReportView: View {
    @Environment(\.dismiss) private var dismiss
    let summary: WorkoutCompletionValidator.WorkoutSummary
    let onSave: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Workout Complete! 🎉")
                            .font(.title.bold())
                        Text(getPersonalMessage())
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Stats grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(
                            icon: "clock",
                            title: "Duration",
                            value: formatDuration(summary.duration),
                            color: .blue
                        )
                        StatCard(
                            icon: "dumbbell",
                            title: "Volume",
                            value: "\(Int(summary.totalVolume)) kg",
                            color: .purple
                        )
                        StatCard(
                            icon: "checkmark.circle",
                            title: "Sets",
                            value: "\(summary.setsCompleted)/\(summary.totalSets)",
                            color: .green
                        )
                        StatCard(
                            icon: "list.bullet",
                            title: "Exercises",
                            value: "\(summary.exercisesCompleted)/\(summary.totalExercises)",
                            color: .orange
                        )
                    }
                    
                    // PRs section
                    if summary.prCount > 0 {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "trophy.fill")
                                    .foregroundStyle(.yellow)
                                Text("Personal Records")
                                    .font(.headline)
                            }
                            Text("You hit \(summary.prCount) new PR\(summary.prCount > 1 ? "s" : "")!")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // New 1RMs section
                    if !summary.new1RMs.isEmpty {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "arrow.up.right.circle.fill")
                                    .foregroundStyle(.green)
                                Text("New 1RM Estimates")
                                    .font(.headline)
                            }
                            ForEach(summary.new1RMs, id: \.exerciseId) { oneRM in
                                HStack {
                                    Text(oneRM.exerciseId)
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(Int(oneRM.new1RM)) kg")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Workout Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button("Save Workout") {
                        onSave()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    private func getPersonalMessage() -> String {
        if !summary.new1RMs.isEmpty {
            return "New PR! 🎉"
        } else if summary.prCount > 0 {
            return "Great work hitting your PRs!"
        } else if summary.setsCompleted >= summary.totalSets {
            return "All sets completed! Amazing work!"
        } else if summary.duration > 3600 {
            return "Over an hour of training! Impressive!"
        } else {
            return "Great work!"
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMins = minutes % 60
            return "\(hours)h \(remainingMins)m"
        }
        return "\(minutes)m \(seconds)s"
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    WorkoutCompletionReportView(
        summary: WorkoutCompletionValidator.WorkoutSummary(
            duration: 3600,
            totalVolume: 12000,
            setsCompleted: 20,
            totalSets: 20,
            exercisesCompleted: 6,
            totalExercises: 6,
            new1RMs: [("ex-1", 105)],
            prCount: 1
        ),
        onSave: {}
    )
}