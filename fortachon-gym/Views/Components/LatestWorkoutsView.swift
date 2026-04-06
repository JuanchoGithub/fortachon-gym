import SwiftUI
import SwiftData
import FortachonCore

struct LatestWorkoutsView: View {
    let sessions: [WorkoutSessionM]
    @State private var showAllWorkouts = false
    
    // Show up to 10 workouts (increased from 3)
    private var displayedSessions: [WorkoutSessionM] {
        if showAllWorkouts {
            return sessions.prefix(50).map { $0 }
        }
        return sessions.prefix(10).map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Latest Workouts")
                    .font(.headline)
                Spacer()
                if sessions.count > 10 {
                    Button(showAllWorkouts ? "Show Less" : "Show All (\(sessions.count))") {
                        showAllWorkouts.toggle()
                    }
                    .font(.caption)
                }
            }
            
            ForEach(displayedSessions) { session in
                NavigationLink(destination: SessionDetailView(session: session)) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(session.routineName)
                            .font(.subheadline)
                        Spacer()
                        Text(formatDuration(from: session.startTime, to: session.endTime))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func formatDuration(from start: Date, to end: Date) -> String {
        let interval = end.timeIntervalSince(start)
        let minutes = Int(interval / 60)
        return "\(minutes)m"
    }
}
