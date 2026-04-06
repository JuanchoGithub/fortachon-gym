import SwiftUI
import FortachonCore

/// P1 #6: Workout details modal that allows editing routine name and notes mid-workout.
struct WorkoutDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let routineName: String
    let notes: String
    let elapsed: TimeInterval
    let completedSets: Int
    let totalSets: Int
    let totalVolume: Double
    
    let onEditNotes: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                // Workout info section
                Section("Workout Info") {
                    HStack {
                        Label("Routine", systemImage: "dumbbell.fill")
                        Spacer()
                        Text(routineName)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Label("Elapsed", systemImage: "clock.fill")
                        Spacer()
                        Text(elapsed.formattedAsWorkout)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                
                // Progress section
                Section("Progress") {
                    HStack {
                        Label("Sets", systemImage: "checkmark.circle.fill")
                        Spacer()
                        Text("\(completedSets) / \(totalSets)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Label("Volume", systemImage: "scalemass.fill")
                        Spacer()
                        if totalVolume > 0 {
                            Text("\(Int(totalVolume)) kg")
                                .foregroundStyle(.secondary)
                        } else {
                            Text("—")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if totalSets > 0 {
                        ProgressView(value: Double(completedSets), total: Double(totalSets))
                            .progressViewStyle(.linear)
                            .tint(progress >= 1.0 ? .green : .blue)
                    }
                }
                
                // Notes section
                Section("Notes") {
                    if notes.isEmpty {
                        Button(action: onEditNotes) {
                            HStack {
                                Image(systemName: "note.text.badge.plus")
                                Text("Add workout notes")
                            }
                        }
                    } else {
                        Button(action: onEditNotes) {
                            HStack {
                                Image(systemName: "note.text")
                                Text("Tap to edit notes")
                            }
                        }
                        Text(notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                }
            }
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { onDismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private var progress: Double {
        guard totalSets > 0 else { return 0 }
        return Double(completedSets) / Double(totalSets)
    }
}