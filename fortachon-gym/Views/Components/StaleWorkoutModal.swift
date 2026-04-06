import SwiftUI
import FortachonCore

// MARK: - Stale Workout Modal

/// A full-screen overlay/modal for detecting stale/inactive workouts.
/// Displayed when a workout has been open for 3+ hours.
struct StaleWorkoutModal: View {
    @Environment(\.dismiss) private var dismiss
    
    let workoutName: String
    let info: StaleWorkoutInfo
    let onContinue: () -> Void
    let onFinish: () -> Void
    
    @State private var isPresented = false
    @State private var scale: CGFloat = 0.9
    @State private var opacity: CGFloat = 0
    
    private var progressPercentage: Double {
        guard info.totalSets > 0 else { return 0 }
        return Double(info.completedSets) / Double(info.totalSets)
    }
    
    private var timeAgoText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: info.lastActivity, relativeTo: Date())
    }
    
    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            // Modal card
            VStack(spacing: 20) {
                // Warning icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.orange)
                    .padding(.top, 8)
                
                // Title
                Text("Stale Workout Detected")
                    .font(.title2.bold())
                
                // Description
                VStack(spacing: 8) {
                    Text("You haven't completed any sets in \(info.hoursInactive) hours.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("Started: \(timeAgoText)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                // Workout info card
                VStack(spacing: 12) {
                    Label(workoutName, systemImage: "dumbbell.fill")
                        .font(.headline)
                    
                    // Progress
                    HStack {
                        Text("\(info.completedSets) of \(info.totalSets) sets completed")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(progressPercentage * 100))%")
                            .font(.subheadline.bold())
                            .foregroundStyle(progressPercentage >= 0.5 ? .green : .orange)
                    }
                    
                    // Progress bar
                    ProgressView(value: progressPercentage)
                        .progressViewStyle(.linear)
                        .tint(progressPercentage >= 0.5 ? .green : .orange)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        onContinue()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Continue Workout")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    }
                    
                    Button(action: {
                        onFinish()
                    }) {
                        HStack {
                            Image(systemName: "flag.checkered")
                            Text("Finish Workout")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 32)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isPresented)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isPresented = true
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

// MARK: - Preview

#Preview {
    StaleWorkoutModal(
        workoutName: "Push Day A",
        info: StaleWorkoutInfo(
            lastActivity: Calendar.current.date(byAdding: .hour, value: -4, to: Date()) ?? Date(),
            hoursInactive: 4,
            completedSets: 8,
            totalSets: 16
        ),
        onContinue: {},
        onFinish: {}
    )
}