import SwiftUI
import FortachonCore

extension Color {
    static var systemTertiary: Color {
        Color(uiColor: .tertiarySystemBackground)
    }
}

struct MuscleHeatmapView: View {
    let freshnessData: [MuscleFreshness]
    
    var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("Muscle Recovery Map")
                    .font(.headline)
            }
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(freshnessData.indices, id: \.self) { index in
                    let muscle = freshnessData[index]
                    MuscleHeatCell(muscleFreshness: muscle)
                }
            }
            
            // Legend
            HStack(spacing: 16) {
                legendItem(color: .green, label: "Ready")
                legendItem(color: .yellow, label: "Recovering")
                legendItem(color: .orange, label: "Fatigued")
                legendItem(color: .red, label: "Rest needed")
            }
            .padding(.top, 4)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct MuscleHeatCell: View {
    let muscleFreshness: MuscleFreshness
    
    var cellColor: Color {
        let pct = muscleFreshness.freshnessPercent
        if pct >= 80 {
            return .green
        } else if pct >= 50 {
            return .yellow
        } else if pct >= 25 {
            return .orange
        } else {
            return .red
        }
    }
    
    var opacity: Double {
        0.3 + (muscleFreshness.freshnessPercent / 100.0) * 0.7
    }
    
    var icon: String {
        switch muscleFreshness.muscleName {
        case "Chest": return "person.arms.spread"
        case "Back": return "figure.walk"
        case "Legs": return "figure.run"
        case "Shoulders": return "person.fill.turn.right"
        case "Arms": return "hand.raised.fill"
        case "Core": return "figure.core.training"
        default: return "star.fill"
        }
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(cellColor)
            
            Text(muscleFreshness.muscleName)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            Text("\(Int(muscleFreshness.freshnessPercent))%")
                .font(.caption.monospacedDigit())
                .foregroundStyle(cellColor)
                .fontWeight(.bold)
            
            // Visual indicator
            VStack(spacing: 2) {
                ForEach(0..<5) { dot in
                    Circle()
                        .fill(dot < filledDots ? cellColor : Color.systemTertiary)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            cellColor
                .opacity(opacity * 0.15)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        )
    }
    
    private var filledDots: Int {
        let pct = muscleFreshness.freshnessPercent
        if pct >= 80 { return 5 }
        if pct >= 60 { return 4 }
        if pct >= 40 { return 3 }
        if pct >= 20 { return 2 }
        return 1
    }
}

#Preview {
    MuscleHeatmapView(freshnessData: [
        MuscleFreshness(muscleName: "Chest", freshnessPercent: 85, lastWorkoutDate: Date().addingTimeInterval(-48 * 3600), volumeInWindow: 5000),
        MuscleFreshness(muscleName: "Back", freshnessPercent: 60, lastWorkoutDate: Date().addingTimeInterval(-24 * 3600), volumeInWindow: 6000),
        MuscleFreshness(muscleName: "Legs", freshnessPercent: 25, lastWorkoutDate: Date().addingTimeInterval(-12 * 3600), volumeInWindow: 8000),
        MuscleFreshness(muscleName: "Shoulders", freshnessPercent: 45, lastWorkoutDate: Date().addingTimeInterval(-36 * 3600), volumeInWindow: 3000),
        MuscleFreshness(muscleName: "Arms", freshnessPercent: 70, lastWorkoutDate: Date().addingTimeInterval(-30 * 3600), volumeInWindow: 2000),
        MuscleFreshness(muscleName: "Core", freshnessPercent: 90, lastWorkoutDate: nil, volumeInWindow: 0)
    ])
}