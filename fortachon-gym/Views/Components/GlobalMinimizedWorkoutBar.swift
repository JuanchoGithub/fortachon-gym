import SwiftUI
import FortachonCore

// MARK: - Global Minimized Workout Bar
// P0 #1 Fix: Persistent workout bar visible across all tabs when minimized.
// This replaces the local MinimizedWorkoutView inside ActiveWorkoutView.

struct GlobalMinimizedWorkoutBar: View {
    @Environment(ActiveWorkoutSession.self) private var session
    @State private var showFinishAlert = false
    
    var body: some View {
        HStack(spacing: 10) {
            // Workout info
            Button {
                // Tap the bar to expand the workout
                NotificationCenter.default.post(name: .expandWorkoutFromMinimized, object: nil)
            } label: {
                HStack(spacing: 8) {
                    // Progress ring
                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 2.5)
                            .frame(width: 28, height: 28)
                        Circle()
                            .trim(from: 0, to: progressFraction)
                            .stroke(Color.green, lineWidth: 2.5)
                            .frame(width: 28, height: 28)
                            .rotationEffect(.degrees(-90))
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 10))
                            .foregroundStyle(.green)
                    }
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(session.routineName)
                            .font(.subheadline.bold())
                            .lineLimit(1)
                        HStack(spacing: 3) {
                            Image(systemName: "timer")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(session.elapsed.formattedAsWorkout)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            if session.totalSets > 0 {
                                Text("• \(session.completedSets)/\(session.totalSets)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(.trailing, 4)
            }
            
            Spacer(minLength: 8)
            
            // Expand button
            Button {
                NotificationCenter.default.post(name: .expandWorkoutFromMinimized, object: nil)
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.body)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            
            // Finish button
            Button {
                showFinishAlert = true
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.body)
                    .foregroundStyle(.green)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
        .alert("Finish Workout?", isPresented: $showFinishAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Finish", role: .destructive) {
                NotificationCenter.default.post(name: .finishWorkoutFromMinimized, object: nil)
            }
        } message: {
            Text("This will save your workout and end the session.")
        }
    }
    
    private var progressFraction: Double {
        guard session.totalSets > 0 else { return 0 }
        return Double(session.completedSets) / Double(session.totalSets)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let finishWorkoutFromMinimized = Notification.Name("finishWorkoutFromMinimized")
    static let expandWorkoutFromMinimized = Notification.Name("expandWorkoutFromMinimized")
}

#Preview {
    @Previewable @State var session = ActiveWorkoutSession()
    
    VStack {
        Spacer()
        GlobalMinimizedWorkoutBar()
            .environment(session)
            .padding(.horizontal)
            .padding(.bottom, 20)
    }
    .onAppear {
        session.start(routineName: "Push Day A")
        session.minimize()
        session.updateProgress(completed: 8, total: 15)
    }
}
