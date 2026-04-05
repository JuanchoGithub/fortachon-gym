import SwiftUI
import FortachonCore

struct UnlockHistoryEntry: Identifiable {
    let id: String
    let title: String
    let desc: String
    let date: Date
    let icon: String
}

struct UnlockHistoryView: View {
    let unlocks: [UnlockHistoryEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.headline)
            
            if unlocks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "trophy")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("No achievements yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Keep training to unlock achievements!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            } else {
                VStack(spacing: 8) {
                    ForEach(unlocks) { unlock in
                        HStack(spacing: 12) {
                            Image(systemName: unlock.icon)
                                .font(.title2)
                                .foregroundStyle(.yellow)
                                .frame(width: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(unlock.title)
                                    .font(.subheadline)
                                Text(unlock.desc)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(unlock.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }
}

#Preview {
    UnlockHistoryView(unlocks: [
        UnlockHistoryEntry(
            id: "1",
            title: "First Workout",
            desc: "Completed your first workout",
            date: Date().addingTimeInterval(-86400 * 7),
            icon: "star.fill"
        ),
        UnlockHistoryEntry(
            id: "2",
            title: "Consistency King",
            desc: "10 workouts completed",
            date: Date().addingTimeInterval(-86400 * 3),
            icon: "crown.fill"
        ),
    ])
}