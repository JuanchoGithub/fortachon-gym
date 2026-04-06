import SwiftUI
import FortachonCore

// MARK: - Confirm New Workout Modal

/// A modal shown when the user tries to start a new workout while one is in progress.
struct ConfirmNewWorkoutModal: View {
    @Environment(\.dismiss) private var dismiss
    
    let workoutName: String
    let startTime: Date
    let onContinue: () -> Void
    let onDiscardAndStartNew: () -> Void
    let onCancel: () -> Void
    
    @State private var isPresented = false
    
    // MARK: - Computed Properties
    
    private var timeAgoText: String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: startTime, to: Date())
        
        if let hours = components.hour, hours > 0 {
            if let minutes = components.minute, minutes > 0 {
                return "\(hours)h \(minutes)m ago"
            }
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else if let minutes = components.minute {
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        }
        return "just now"
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Icon
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)
                
                // Title and message
                VStack(spacing: 8) {
                    Text("Active Workout in Progress")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    
                    Text("You have an unfinished workout **\"\(workoutName)\"** from \(timeAgoText). What would you like to do?")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Divider()
                
                // Action buttons
                VStack(spacing: 12) {
                    // Continue Previous
                    Button(action: {
                        onContinue()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "arrowshape.right.fill")
                            Text("Continue Previous")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    }
                    
                    // Discard & Start New
                    Button(action: {
                        onDiscardAndStartNew()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Discard & Start New")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                    }
                    
                    // Cancel
                    Button(action: {
                        onCancel()
                        dismiss()
                    }) {
                        Text("Cancel")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.systemGray5))
                            .foregroundStyle(.primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
            .presentationDetents([.fraction(0.45)])
            .presentationCornerRadius(20)
            .onAppear {
                withAnimation(.spring(response: 0.3)) {
                    isPresented = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ConfirmNewWorkoutModal(
        workoutName: "Push Day A",
        startTime: Calendar.current.date(byAdding: .minute, value: -45, to: Date()) ?? Date(),
        onContinue: {},
        onDiscardAndStartNew: {},
        onCancel: {}
    )
}