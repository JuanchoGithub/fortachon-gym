import SwiftUI
import FortachonCore

/// Card for cardio/duration exercises during active workout
struct CardioExerciseCard: View {
    let exercise: ExerciseM
    let idx: Int
    let existingSets: [PerformedSetM]
    let onComplete: (_ durationSecs: Int, _ distance: Double) -> Void
    
    @State private var durationMinutes: Int = 0
    @State private var durationSeconds: Int = 30
    @State private var distance: Double = 0
    @State private var intensity: CardioIntensity = .moderate
    @State private var isExpanded = true
    
    private var totalSeconds: Int {
        durationMinutes * 60 + durationSeconds
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                    Text("\(idx + 1). \(exercise.name)")
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
            }
            
            if isExpanded {
                VStack(spacing: 16) {
                    // Duration input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Duration")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 16) {
                            // Minutes
                            VStack {
                                Text("Min")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Stepper("", value: $durationMinutes, in: 0...120)
                                    .labelsHidden()
                                Text("\(durationMinutes)")
                                    .font(.title2.monospacedDigit())
                            }
                            .frame(maxWidth: .infinity)
                            
                            // Seconds
                            VStack {
                                Text("Sec")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Stepper("", value: $durationSeconds, in: 0...59, step: 5)
                                    .labelsHidden()
                                Text("\(durationSeconds)")
                                    .font(.title2.monospacedDigit())
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    
                    // Distance input (optional)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Distance (optional)")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            TextField("0", value: $distance, format: .number.precision(.fractionLength(2)))
                                .keyboardType(.decimalPad)
                                .font(.title2.monospacedDigit())
                            Text("km")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Intensity selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Intensity")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                        
                        Picker("Intensity", selection: $intensity) {
                            ForEach(CardioIntensity.allCases, id: \.self) { level in
                                Text(level.label)
                                    .tag(level)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Complete button
                    Button(action: {
                        onComplete(totalSeconds, distance)
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Complete Set")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(totalSeconds > 0 ? Color.green : Color.gray)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    }
                    .disabled(totalSeconds == 0)
                    
                    // Existing sets
                    if !existingSets.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Completed Sets")
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                            
                            ForEach(existingSets.indices, id: \.self) { i in
                                let set = existingSets[i]
                                HStack {
                                    Text("Set \(i + 1)")
                                        .font(.subheadline)
                                    Spacer()
                                    Text(formatDuration(set.setTime ?? 0))
                                        .font(.subheadline.monospacedDigit())
                                    if set.weight > 0 {
                                        Text("\(String(format: "%.2f", set.weight)) km")
                                            .font(.caption.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                    }
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

/// Cardio intensity levels
enum CardioIntensity: String, CaseIterable, Identifiable {
    case easy
    case moderate
    case hard
    case maximum
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .easy: "Easy (Conversation pace)"
        case .moderate: "Moderate (Breathing harder)"
        case .hard: "Hard (Can't talk)"
        case .maximum: "Maximum (All out)"
        }
    }
    
    var color: Color {
        switch self {
        case .easy: .green
        case .moderate: .blue
        case .hard: .orange
        case .maximum: .red
        }
    }
}

#Preview {
    CardioExerciseCard(
        exercise: ExerciseM(
            id: "ex-cardio-1",
            name: "Treadmill Run",
            bodyPart: "Full Body",
            category: "Cardio"
        ),
        idx: 0,
        existingSets: [],
        onComplete: { _, _ in }
    )
    .padding()
}