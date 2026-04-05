import SwiftUI
import FortachonCore

struct QuickTrainingButtonsView: View {
    @State private var isExpanded = true
    let onStartSession: (RoutineFocus) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("Quick Training")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .rotationEffect(isExpanded ? .degrees(90) : .zero)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    QuickSessionButton(title: "Push", icon: "arrowshape.up.fill", color: .blue) {
                        onStartSession(.push)
                    }
                    QuickSessionButton(title: "Pull", icon: "arrowshape.down.fill", color: .purple) {
                        onStartSession(.pull)
                    }
                    QuickSessionButton(title: "Legs", icon: "figure.walk", color: .green) {
                        onStartSession(.legs)
                    }
                }
                HStack(spacing: 8) {
                    TimerButton(label: "5 min")
                    TimerButton(label: "10 min")
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct QuickSessionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.title2)
                Text(title).font(.caption.bold())
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(color, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct TimerButton: View {
    let label: String
    
    var body: some View {
        Button { } label: {
            VStack(spacing: 4) {
                Image(systemName: "stopwatch")
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        }
    }
}