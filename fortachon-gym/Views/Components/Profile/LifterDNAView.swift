import SwiftUI
import FortachonCore

struct LifterDNAView: View {
    let stats: LifterStats
    
    var archetypeIcon: String {
        switch stats.archetype {
        case .powerbuilder: return "dumbbell.fill"
        case .bodybuilder: return "person.fill"
        case .endurance: return "figure.run"
        case .hybrid: return "figure.mixed.cardio"
        case .beginner: return "star.fill"
        }
    }
    
    var archetypeTitle: String {
        switch stats.archetype {
        case .powerbuilder: return "Powerbuilder"
        case .bodybuilder: return "Bodybuilder"
        case .endurance: return "Endurance"
        case .hybrid: return "Hybrid"
        case .beginner: return "Beginner"
        }
    }
    
    var archetypeColor: Color {
        switch stats.archetype {
        case .powerbuilder: return .purple
        case .bodybuilder: return .pink
        case .endurance: return .green
        case .hybrid: return .blue
        case .beginner: return .yellow
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "fingerprint")
                    .foregroundStyle(.blue)
                Text("Lifter DNA")
                    .font(.headline)
            }
            
            // Archetype Badge
            HStack(spacing: 12) {
                Image(systemName: archetypeIcon)
                    .font(.system(size: 32))
                    .foregroundStyle(archetypeColor)
                    .frame(width: 50, height: 50)
                    .background(archetypeColor.opacity(0.15), in: Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(archetypeTitle)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(archetypeColor)
                    Text("Based on your training patterns")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(stats.experienceLevel)")
                        .font(.title3.weight(.bold))
                    Text("Workouts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            
            // Score Cards
            VStack(spacing: 8) {
                scoreRow(icon: "calendar.badge.clock", title: "Consistency", value: stats.consistencyScore, color: .blue)
                scoreRow(icon: "chart.bar.fill", title: "Volume", value: stats.volumeScore, color: .green)
                scoreRow(icon: "bolt.fill", title: "Intensity", value: stats.intensityScore, color: .orange)
                scoreRow(icon: "gauge.high", title: "Efficiency", value: stats.efficiencyScore, color: .purple)
            }
            
            // Raw Stats
            VStack(alignment: .leading, spacing: 6) {
                Text("Raw Numbers")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading) {
                        Text("\(stats.rawConsistency)")
                            .font(.headline.monospacedDigit())
                        Text("Workouts this month")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(alignment: .leading) {
                        Text("\(stats.rawVolume)")
                            .font(.headline.monospacedDigit())
                        Text("Avg volume/session")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(alignment: .leading) {
                        Text("\(stats.rawIntensity, specifier: "%.1f")")
                            .font(.headline.monospacedDigit())
                        Text("Avg compound reps")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            
            if !stats.favMuscle.isEmpty && stats.favMuscle != "N/A" {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.yellow)
                    Text("Most trained muscle group: \(stats.favMuscle)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func scoreRow(icon: String, title: String, value: Int, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            // Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.tertiary)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * Double(value) / 100, height: 8)
                }
            }
            .frame(width: 100, height: 8)
            
            Text("\(value)%")
                .font(.subheadline.monospacedDigit().weight(.medium))
                .frame(width: 40, alignment: .trailing)
        }
    }
}

#Preview {
    LifterDNAView(stats: LifterStats(
        consistencyScore: 75,
        volumeScore: 60,
        intensityScore: 85,
        experienceLevel: 47,
        archetype: .powerbuilder,
        favMuscle: "Chest",
        efficiencyScore: 92,
        rawConsistency: 9,
        rawVolume: 12500,
        rawIntensity: 6.5
    ))
}