import SwiftUI
import SwiftData
import FortachonCore

struct LatestWorkoutsView: View {
    let sessions: [WorkoutSessionM]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Latest Workouts")
                .font(.headline)
            
            ForEach(sessions) { session in
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
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private func formatDuration(from start: Date, to end: Date) -> String {
        let interval = end.timeIntervalSince(start)
        let minutes = Int(interval / 60)
        return "\(minutes)m"
    }
}