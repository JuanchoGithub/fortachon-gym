import SwiftUI
import FortachonCore

// MARK: - Check-in Card View

struct CheckInCardView: View {
    @State private var selectedReason: CheckInReason?
    @State private var showSubmit = false
    let onSubmit: (CheckInReason) -> Void
    let onSnooze: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back! 👋")
                        .font(.title2.bold())
                    Text("We haven't seen you in a while. Everything okay?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            
            // Reason options
            VStack(spacing: 8) {
                ForEach(CheckInReason.allCases, id: \.self) { reason in
                    CheckInReasonButton(
                        reason: reason,
                        isSelected: selectedReason == reason
                    ) {
                        selectedReason = reason
                    }
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Remind Me Tomorrow") {
                    onSnooze()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                
                Spacer()
                
                Button("Submit") {
                    if let reason = selectedReason {
                        onSubmit(reason)
                    }
                }
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 24)
                .background(
                    selectedReason != nil ? Color.blue : Color.gray,
                    in: Capsule()
                )
                .disabled(selectedReason == nil)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}

// MARK: - Check-in Reason Button

struct CheckInReasonButton: View {
    let reason: CheckInReason
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(reason.emoji)
                    .font(.title2)
                Text(reason.label)
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                } else {
                    Circle()
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)
                }
            }
            .padding()
            .background(
                isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6),
                in: RoundedRectangle(cornerRadius: 12)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    CheckInCardView(
        onSubmit: { _ in },
        onSnooze: {}
    )
    .padding()
}