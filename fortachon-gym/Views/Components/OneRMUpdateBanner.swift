import SwiftUI

// MARK: - One Rep Max Update Banner

struct OneRMUpdateBanner: View {
    let updates: [(exerciseName: String, oldMax: Double, newMax: Double)]
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
                Text("New Personal Records!")
                    .font(.headline)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            
            ForEach(updates.indices, id: \.self) { idx in
                let update = updates[idx]
                HStack {
                    Text(update.exerciseName)
                        .font(.subheadline)
                        .lineLimit(1)
                    Spacer()
                    Text("\(Int(update.oldMax)) → \(Int(update.newMax)) kg")
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        OneRMUpdateBanner(
            updates: [
                ("Bench Press", 80, 85),
                ("Squat", 100, 105),
                ("Deadlift", 120, 130)
            ],
            onDismiss: {}
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}