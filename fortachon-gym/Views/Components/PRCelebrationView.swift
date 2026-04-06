import SwiftUI

// MARK: - PR Celebration View

struct PRCelebrationView: View {
    let exerciseName: String
    let prType: PRType
    let prValue: Double
    @Binding var isShowing: Bool
    
    enum PRType: String {
        case weight = "New Weight PR"
        case reps = "New Reps PR"
        case volume = "New Volume PR"
        case oneRM = "New 1RM PR"
        
        var icon: String {
            switch self {
            case .weight: "arrow.up.right"
            case .reps: "repeat"
            case .volume: "chart.line.uptrend.xyaxis"
            case .oneRM: "trophy.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .weight: .blue
            case .reps: .green
            case .volume: .orange
            case .oneRM: .yellow
            }
        }
    }
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var rotation: Double = -30
    @State private var confettiOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isShowing = false
                    }
                }
            
            // Celebration card
            VStack(spacing: 20) {
                // Trophy icon with animation
                ZStack {
                    Circle()
                        .fill(prType.color.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: prType.icon)
                        .font(.system(size: 50))
                        .foregroundStyle(prType.color)
                        .scaleEffect(scale)
                        .rotationEffect(.degrees(rotation))
                }
                
                // PR text
                VStack(spacing: 8) {
                    Text("🎉 NEW PR! 🎉")
                        .font(.title.bold())
                        .foregroundStyle(prType.color)
                    
                    Text(exerciseName)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    
                    Text(formatPRValue(prValue))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
                
                // Dismiss button
                Button {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isShowing = false
                    }
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(prType.color)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 40)
            .opacity(opacity)
            
            // Confetti particles
            ForEach(0..<20, id: \.self) { i in
                ConfettiParticle(
                    index: i,
                    offset: confettiOffset,
                    color: confettiColors[i % confettiColors.count]
                )
            }
        }
        .onAppear {
            animateIn()
        }
    }
    
    private func animateIn() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            scale = 1
            opacity = 1
            rotation = 0
        }
        
        withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
            confettiOffset = -500
        }
    }
    
    private func formatPRValue(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }
}

// MARK: - Confetti Particle

struct ConfettiParticle: View {
    let index: Int
    let offset: CGFloat
    let color: Color
    
    private var startX: CGFloat {
        CGFloat.random(in: -150...150)
    }
    
    private var startY: CGFloat {
        CGFloat.random(in: -100...50)
    }
    
    private var rotation: Double {
        Double.random(in: 0...360)
    }
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 8, height: 8)
            .position(x: startX, y: startY)
            .rotationEffect(.degrees(rotation))
            .offset(y: offset + CGFloat.random(in: -50...50))
            .opacity(max(0, 1 + offset / 500))
    }
}

private let confettiColors: [Color] = [
    .red, .blue, .green, .yellow, .orange, .purple, .pink, .mint
]

// MARK: - PR Celebration Modifier

struct PRCelebrationModifier: ViewModifier {
    @Binding var isShowing: Bool
    let exerciseName: String
    let prType: PRCelebrationView.PRType
    let prValue: Double
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if isShowing {
                    PRCelebrationView(
                        exerciseName: exerciseName,
                        prType: prType,
                        prValue: prValue,
                        isShowing: $isShowing
                    )
                    .transition(.opacity)
                    .zIndex(100)
                }
            }
    }
}

// MARK: - Extension for easy use

extension View {
    func prCelebration(
        isShowing: Binding<Bool>,
        exerciseName: String,
        prType: PRCelebrationView.PRType,
        prValue: Double
    ) -> some View {
        modifier(PRCelebrationModifier(
            isShowing: isShowing,
            exerciseName: exerciseName,
            prType: prType,
            prValue: prValue
        ))
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State var isShowing = true
        
        var body: some View {
            Color.black
                .overlay {
                    if isShowing {
                        PRCelebrationView(
                            exerciseName: "Bench Press",
                            prType: .oneRM,
                            prValue: 100,
                            isShowing: $isShowing
                        )
                    }
                }
        }
    }
    return PreviewWrapper()
}