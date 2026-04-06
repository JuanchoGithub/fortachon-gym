import SwiftUI
import FortachonCore

struct WorkoutSessionHeaderView: View {
    let routineName: String
    let totalVolume: Double
    let elapsed: TimeInterval
    let completedCount: Int
    let totalCount: Int
    let progress: Double
    let isReorderMode: Bool
    let notesHasContent: Bool
    let audioCoachEnabled: Bool
    let onMinimize: () -> Void
    let onStartReorder: () -> Void
    let onCancelReorder: () -> Void
    let onSaveReorder: () -> Void
    let onSupersetManager: () -> Void
    let onPlateCalculator: () -> Void
    let onToggleAudioCoach: () -> Void
    let onNotes: () -> Void
    let onWorkoutDetails: () -> Void
    let onCoachSuggest: () -> Void
    let onFinish: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header Row
            HStack {
                VStack(alignment: .leading) {
                    HStack(spacing: 6) {
                        Text(routineName).font(.title3.bold())
                        if totalVolume > 0 {
                            Text("\(Int(totalVolume))kg")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.blue)
                        }
                    }
                    HStack(spacing: 8) {
                        Text(elapsed.formattedAsWorkout)
                            .font(.title2.monospacedDigit())
                            .foregroundStyle(.secondary)
                        if totalCount > 0 {
                            Text("\u{2022} \(completedCount)/\(totalCount) sets")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if totalCount > 0 {
                        let pct = progress * 100
                        Text("\(Int(pct))% complete")
                            .font(.caption)
                            .foregroundStyle(pct >= 100 ? .green : .blue)
                    }
                }
                Spacer()
                HStack(spacing: 8) {
                    Button("Minimize", systemImage: "arrow.down.left.and.arrow.up.right") {
                        onMinimize()
                    }
                    if !isReorderMode {
                        Button("Reorder", systemImage: "arrow.up.arrow.down") {
                            onStartReorder()
                        }
                    } else {
                        Button("Cancel", systemImage: "xmark") {
                            onCancelReorder()
                        }
                        .tint(.red)
                        Button("Save", systemImage: "checkmark") {
                            onSaveReorder()
                        }
                        .tint(.green)
                    }
                    Button(action: onSupersetManager) {
                        Image(systemName: "rectangle.3.group.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    Button(action: onPlateCalculator) {
                        Image(systemName: "scalemass.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    Button(action: onToggleAudioCoach) {
                        Image(systemName: audioCoachEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.title3)
                            .foregroundStyle(audioCoachEnabled ? .blue : .secondary)
                    }
                    Button(action: onNotes) {
                        Image(systemName: notesHasContent ? "note.text" : "note.text.badge.plus")
                            .font(.title3)
                            .foregroundStyle(notesHasContent ? .blue : .secondary)
                    }
                    Button(action: onWorkoutDetails) {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    Button(action: onCoachSuggest) {
                        Image(systemName: "brain.head.profile")
                            .font(.title3)
                            .foregroundStyle(.purple)
                    }
                    Button("Finish") { onFinish() }
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
            .padding(.vertical)
            
            // MARK: - Progress Bar
            if totalCount > 0 {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(progress >= 1.0 ? .green : .blue)
                    .padding(.horizontal)
            }
            
            Divider()
        }
    }
}