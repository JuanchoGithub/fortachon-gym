import SwiftUI
import FortachonCore

// MARK: - Muscle Freshness Badge

/// Small badge showing muscle freshness for an exercise
struct MuscleFreshnessBadge: View {
    let freshnessPercent: Double
    let primaryMuscles: [String]
    
    var body: some View {
        HStack(spacing: 4) {
            // Freshness indicator dot
            Circle()
                .fill(getFreshnessColor(freshnessPercent))
                .frame(width: 8, height: 8)
            
            Text("\(Int(freshnessPercent))%")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(getFreshnessColor(freshnessPercent))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color(.systemBackground).opacity(0.5), in: Capsule())
    }
}

// MARK: - Muscle Freshness Detail View

/// Detailed view showing freshness for each primary muscle of an exercise
struct MuscleFreshnessDetailView: View {
    let exerciseId: String
    let exerciseName: String
    let primaryMuscles: [String]
    let freshnessData: [MuscleFreshness]
    let exercises: [Exercise]
    
    // Compute freshness per muscle
    private var muscleFreshnessList: [(name: String, freshness: Double)] {
        let freshnessMap = Dictionary(uniqueKeysWithValues: freshnessData.map { ($0.muscleName, $0.freshnessPercent) })
        
        return primaryMuscles.compactMap { muscleKey -> (name: String, freshness: Double)? in
            let displayName = formatMuscleName(muscleKey)
            guard let freshness = freshnessMap[displayName] else { return nil }
            return (displayName, freshness)
        }
    }
    
    private var averageFreshness: Double {
        guard !muscleFreshnessList.isEmpty else { return 100 }
        return muscleFreshnessList.reduce(0) { $0 + $1.freshness } / Double(muscleFreshnessList.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(exerciseName)
                    .font(.headline)
                Spacer()
                Text("Recovery")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Overall freshness
            HStack(spacing: 8) {
                Circle()
                    .fill(getFreshnessColor(averageFreshness))
                    .frame(width: 12, height: 12)
                Text("\(Int(averageFreshness))%")
                    .font(.title2.bold())
                    .foregroundStyle(getFreshnessColor(averageFreshness))
                Spacer()
                freshnessLabel(for: averageFreshness)
                    .font(.caption)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(getFreshnessColor(averageFreshness).opacity(0.1))
            )
            
            // Individual muscles
            if !muscleFreshnessList.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Muscles")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    ForEach(muscleFreshnessList, id: \.name) { muscle in
                        MuscleProgressBar(muscleName: muscle.name, progress: muscle.freshness)
                    }
                }
            } else {
                Text("No recent data for these muscles")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func freshnessLabel(for percent: Double) -> some View {
        switch percent {
        case 80...100:
            Text("Fully Recovered ✓")
                .foregroundStyle(.green)
        case 50..<80:
            Text("Recovering...")
                .foregroundStyle(.yellow)
        case 25..<50:
            Text("Fatigued")
                .foregroundStyle(.orange)
        default:
            Text("Very Fatigued ⚠️")
                .foregroundStyle(.red)
        }
    }
}

// MARK: - Muscle Progress Bar

struct MuscleProgressBar: View {
    let muscleName: String
    let progress: Double
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(muscleName)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(progress))%")
                    .font(.subheadline.monospacedDigit().weight(.medium))
                    .foregroundStyle(getFreshnessColor(progress))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(getFreshnessColor(progress).opacity(0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(getFreshnessColor(progress))
                        .frame(width: geometry.size.width * progress / 100, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Inline Freshness Indicator (for exercise cards)

/// Minimal inline indicator for exercise cards
struct InlineFreshnessIndicator: View {
    let freshnessPercent: Double?
    
    var body: some View {
        Group {
            if let percent = freshnessPercent {
                HStack(spacing: 3) {
                    Circle()
                        .fill(getFreshnessColor(percent))
                        .frame(width: 6, height: 6)
                    Text("\(Int(percent))%")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(getFreshnessColor(percent))
                }
            } else {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary.opacity(0.4))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            // Badge preview
            VStack(spacing: 8) {
                Text("Badges")
                    .font(.headline)
                HStack(spacing: 12) {
                    MuscleFreshnessBadge(freshnessPercent: 25, primaryMuscles: ["pectorals"])
                    MuscleFreshnessBadge(freshnessPercent: 50, primaryMuscles: ["pectorals"])
                    MuscleFreshnessBadge(freshnessPercent: 80, primaryMuscles: ["pectorals"])
                    MuscleFreshnessBadge(freshnessPercent: 100, primaryMuscles: ["pectorals"])
                }
            }
            .padding()
            
            // Inline indicator
            VStack(spacing: 8) {
                Text("Inline Indicators")
                    .font(.headline)
                HStack(spacing: 12) {
                    InlineFreshnessIndicator(freshnessPercent: nil)
                    InlineFreshnessIndicator(freshnessPercent: 30)
                    InlineFreshnessIndicator(freshnessPercent: 65)
                    InlineFreshnessIndicator(freshnessPercent: 90)
                }
            }
            .padding()
            
            // Detail view
            Text("Detail View")
                .font(.headline)
            
            MuscleFreshnessDetailView(
                exerciseId: "ex-1",
                exerciseName: "Bench Press",
                primaryMuscles: ["pectorals", "frontDelts"],
                freshnessData: [
                    MuscleFreshness(muscleName: "Chest", freshnessPercent: 45, lastWorkoutDate: Date().addingTimeInterval(-24 * 3600), volumeInWindow: 6000),
                    MuscleFreshness(muscleName: "Front Delts", freshnessPercent: 60, lastWorkoutDate: Date().addingTimeInterval(-36 * 3600), volumeInWindow: 3000),
                    MuscleFreshness(muscleName: "Triceps", freshnessPercent: 80, lastWorkoutDate: Date().addingTimeInterval(-48 * 3600), volumeInWindow: 2000),
                ],
                exercises: [
                    Exercise(id: "ex-1", name: "Bench Press", bodyPart: .chest, category: .barbell, primaryMuscles: ["pectorals", "frontDelts"])
                ]
            )
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
            
            Spacer()
        }
        .padding()
    }
}