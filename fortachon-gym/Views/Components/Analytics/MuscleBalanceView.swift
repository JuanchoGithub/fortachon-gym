import SwiftUI
import Charts
import FortachonCore

// MARK: - Muscle Balance View

struct MuscleBalanceView: View {
    let sessions: [WorkoutSessionM]
    let exercises: [ExerciseM]
    
    // Calculate muscle group volume
    private var muscleVolumes: [(muscle: String, volume: Double)] {
        var volumes: [String: Double] = [:]
        
        for session in sessions {
            for ex in session.exercises {
                guard let exerciseDef = exercises.first(where: { $0.id == ex.exerciseId }) else { continue }
                
                let completedSets = ex.sets.filter { $0.isComplete }
                let volume = completedSets.reduce(0.0) { $0 + ($1.weight * Double($1.reps)) }
                
                // Map exercise to primary muscle
                let primaryMuscle = exerciseDef.bodyPartStr
                volumes[primaryMuscle, default: 0] += volume
            }
        }
        
        return volumes.sorted { $0.value > $1.value }.map { (muscle: $0.key, volume: $0.value) }
    }
    
    private var totalVolume: Double {
        muscleVolumes.reduce(0) { $0 + $1.volume }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Muscle Balance")
                .font(.headline)
            
            if muscleVolumes.isEmpty {
                ContentUnavailableView(
                    "No Data",
                    systemImage: "chart.pie",
                    description: Text("Complete workouts to see muscle balance analysis.")
                )
                .frame(height: 200)
            } else {
                // Volume by muscle group
                VStack(spacing: 8) {
                    ForEach(muscleVolumes, id: \.muscle) { item in
                        MuscleBalanceRow(
                            muscle: item.muscle,
                            volume: item.volume,
                            totalVolume: totalVolume,
                            color: muscleColor(for: item.muscle)
                        )
                    }
                }
                
                // Radar chart placeholder
                Chart {
                    ForEach(muscleVolumes, id: \.muscle) { item in
                        let percentage = totalVolume > 0 ? item.volume / totalVolume * 100 : 0
                        BarMark(
                            x: .value("Muscle", item.muscle),
                            y: .value("Volume %", percentage)
                        )
                        .foregroundStyle(muscleColor(for: item.muscle))
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("\(Int(doubleValue))%")
                            }
                        }
                    }
                }
                .chartXAxisLabel("Muscle Group")
                .chartYAxisLabel("Volume %")
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func muscleColor(for muscle: String) -> Color {
        let colors: [String: Color] = [
            "Chest": .red,
            "Back": .blue,
            "Legs": .green,
            "Glutes": .purple,
            "Shoulders": .orange,
            "Biceps": .pink,
            "Triceps": .yellow,
            "Core": .cyan,
            "Full Body": .indigo,
            "Calves": .brown,
            "Forearms": .mint
        ]
        return colors[muscle] ?? .gray
    }
}

// MARK: - Muscle Balance Row

struct MuscleBalanceRow: View {
    let muscle: String
    let volume: Double
    let totalVolume: Double
    let color: Color
    
    var percentage: Double {
        totalVolume > 0 ? volume / totalVolume * 100 : 0
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                Text(muscle)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(percentage))%")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Preview

#Preview {
    MuscleBalanceView(sessions: [], exercises: [])
        .padding()
}