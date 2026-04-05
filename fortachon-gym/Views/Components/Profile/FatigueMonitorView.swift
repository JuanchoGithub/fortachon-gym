import SwiftUI
import FortachonCore

struct FatigueMonitorView: View {
    let muscleFreshness: [MuscleFreshness]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .foregroundStyle(.red)
                Text("Recovery Status")
                    .font(.headline)
            }
            
            VStack(spacing: 8) {
                ForEach(muscleFreshness.indices, id: \.self) { index in
                    let muscle = muscleFreshness[index]
                    MuscleRecoveryRow(muscleFreshness: muscle)
                }
            }
            
            Text("Based on your recent training volume and recovery time")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct MuscleRecoveryRow: View {
    let muscleFreshness: MuscleFreshness
    
    var recoveryColor: Color {
        switch muscleFreshness.freshnessPercent {
        case 80...100: return .green
        case 50..<80: return .yellow
        case 25..<50: return .orange
        default: return .red
        }
    }
    
    var recoveryText: String {
        switch muscleFreshness.freshnessPercent {
        case 80...100: return "Recovered"
        case 50..<80: return "Recovering"
        case 25..<50: return "Fatigued"
        default: return "Very Fatigued"
        }
    }
    
    var timeSinceWorkout: String? {
        guard let lastDate = muscleFreshness.lastWorkoutDate else { return nil }
        let hours = Date().timeIntervalSince(lastDate) / 3600
        if hours < 24 {
            return "\(Int(hours))h ago"
        } else {
            return "\(Int(hours / 24))d ago"
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(muscleFreshness.muscleName)
                        .font(.subheadline.weight(.medium))
                    if let timeAgo = timeSinceWorkout {
                        Text(timeAgo)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Text("\(Int(muscleFreshness.freshnessPercent))%")
                    .font(.subheadline.monospacedDigit().weight(.medium))
                    .foregroundStyle(recoveryColor)
                
                Text(recoveryText)
                    .font(.caption)
                    .foregroundStyle(recoveryColor)
                    .frame(width: 75, alignment: .trailing)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.tertiary)
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [recoveryColor.opacity(0.6), recoveryColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * muscleFreshness.freshnessPercent / 100, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

#Preview {
    FatigueMonitorView(muscleFreshness: [
        MuscleFreshness(muscleName: "Chest", freshnessPercent: 85, lastWorkoutDate: Date().addingTimeInterval(-48 * 3600), volumeInWindow: 5000),
        MuscleFreshness(muscleName: "Back", freshnessPercent: 60, lastWorkoutDate: Date().addingTimeInterval(-24 * 3600), volumeInWindow: 6000),
        MuscleFreshness(muscleName: "Legs", freshnessPercent: 25, lastWorkoutDate: Date().addingTimeInterval(-12 * 3600), volumeInWindow: 8000),
        MuscleFreshness(muscleName: "Shoulders", freshnessPercent: 45, lastWorkoutDate: Date().addingTimeInterval(-36 * 3600), volumeInWindow: 3000),
        MuscleFreshness(muscleName: "Arms", freshnessPercent: 70, lastWorkoutDate: Date().addingTimeInterval(-30 * 3600), volumeInWindow: 2000),
        MuscleFreshness(muscleName: "Core", freshnessPercent: 90, lastWorkoutDate: nil, volumeInWindow: 0)
    ])
}