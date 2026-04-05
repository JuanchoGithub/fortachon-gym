import SwiftUI
import FortachonCore

/// A card view for cardio exercises (running, cycling, swimming) with duration and distance tracking.
struct CardioExerciseCard: View {
    let exercise: ExerciseM
    let idx: Int
    let existingSets: [PerformedSetM]
    let onAddSet: (Int, Double) -> Void  // duration in seconds, distance in km
    
    @State private var durationMinutes: Double = 30.0
    @State private var distanceKm: Double = 5.0
    @FocusState private var focusedField: CardioField?
    
    enum CardioField { case duration, distance }
    
    init(exercise: ExerciseM, idx: Int, existingSets: [PerformedSetM] = [], onAddSet: @escaping (Int, Double) -> Void) {
        self.exercise = exercise
        self.idx = idx
        self.existingSets = existingSets
        self.onAddSet = onAddSet
        // Pre-fill with last session values if available
        if let last = existingSets.last, let secs = last.setTime, last.weight > 0 {
            _durationMinutes = State(initialValue: Double(secs) / 60.0)
            _distanceKm = State(initialValue: last.weight)
        }
    }
    
    private var speedKmh: Double {
        guard durationMinutes > 0 else { return 0 }
        return distanceKm / (durationMinutes / 60.0)
    }
    
    private var paceMinKm: Double {
        guard distanceKm > 0 else { return 0 }
        return durationMinutes / distanceKm
    }
    
    private var cardioSets: [PerformedSetM] {
        existingSets.filter { $0.setTypeStr != "warmup" && $0.setTime != nil && $0.weight > 0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "figure.run")
                    .font(.title2)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading) {
                    Text(exercise.name)
                        .font(.headline)
                    Text("Cardio Exercise")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            
            Divider()
            
            // Duration Input
            VStack(alignment: .leading, spacing: 6) {
                Text("Duration (minutes)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack {
                    Stepper("", value: $durationMinutes, in: 1...240, step: 1)
                        .labelsHidden()
                    TextField("Min", value: $durationMinutes, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .duration)
                        .frame(width: 70)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            }
            
            // Distance Input
            VStack(alignment: .leading, spacing: 6) {
                Text("Distance (km)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack {
                    Stepper("", value: $distanceKm, in: 0.1...100, step: 0.1)
                        .labelsHidden()
                    TextField("Km", value: $distanceKm, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .distance)
                        .frame(width: 70)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            }
            
            // Calculated Stats
            if durationMinutes > 0 && distanceKm > 0 {
                Divider()
                HStack(spacing: 20) {
                    VStack {
                        Text("Speed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.1f km/h", speedKmh))
                            .font(.title3.bold())
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                    
                    VStack {
                        Text("Pace")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formatPace(paceMinKm))
                            .font(.title3.bold())
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 8)
            }
            
            // Save Button
            Button(action: saveSet) {
                Label("Save Cardio Set", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(.white)
                    .background(Color.orange)
                    .clipShape(Capsule())
            }
            
            // Previous cardio sets
            if !cardioSets.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("Previous Sets")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(Array(cardioSets.enumerated()), id: \.offset) { i, set in
                        HStack {
                            Text("Set \(i + 1)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if let secs = set.setTime {
                                Text(String(format: "%.0f min", Double(secs) / 60.0))
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                            }
                            if set.weight > 0 {
                                Text(String(format: "%.1f km", set.weight))
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .onTapGesture { focusedField = nil }
    }
    
    private func saveSet() {
        let durationSecs = Int(durationMinutes * 60)
        onAddSet(durationSecs, distanceKm)
    }
    
    private func formatPace(_ paceMinKm: Double) -> String {
        guard paceMinKm > 0 else { return "--:--" }
        let minutes = Int(paceMinKm)
        let seconds = Int((paceMinKm - Double(minutes)) * 60)
        return String(format: "%d:%02d /km", minutes, seconds)
    }
}