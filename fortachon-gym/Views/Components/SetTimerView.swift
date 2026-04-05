import SwiftUI

// MARK: - Set Timer Overlay View

struct SetTimerOverlay: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var timeRemaining: TimeInterval
    let totalTime: TimeInterval
    let exerciseName: String
    
    @State private var timerTask: Task<Void, Never>?
    @State private var internalTimeRemaining: TimeInterval
    @State private var soundEffects = SoundEffectsService()
    
    init(timeRemaining: Binding<TimeInterval>, totalTime: TimeInterval, exerciseName: String = "Timed Set") {
        self._timeRemaining = timeRemaining
        self.totalTime = totalTime
        self.exerciseName = exerciseName
        _internalTimeRemaining = State(initialValue: timeRemaining.wrappedValue)
    }
    
    var progress: Double {
        guard totalTime > 0 else { return 0 }
        return 1.0 - (internalTimeRemaining / totalTime)
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                // Header
                Text(exerciseName)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                
                Text("Hold Position")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                // Circular progress
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 10)
                        .frame(width: 220, height: 220)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(-90))
                    
                    Text(internalTimeRemaining.formattedAsTimer)
                        .font(.system(size: 52, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }
                
                // Quick time presets
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach([10, 20, 30, 45, 60, 90], id: \.self) { secs in
                            Button {
                                let newTotal = TimeInterval(secs)
                                internalTimeRemaining = min(internalTimeRemaining, newTotal)
                                timeRemaining = internalTimeRemaining
                            } label: {
                                Text("\(secs)s")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        internalTimeRemaining == TimeInterval(secs) ? Color.purple : Color(.systemGray5),
                                        in: Capsule()
                                    )
                                    .foregroundStyle(internalTimeRemaining == TimeInterval(secs) ? .white : .secondary)
                            }
                        }
                    }
                }
                
                // Controls
                HStack(spacing: 20) {
                    Button {
                        internalTimeRemaining = max(0, internalTimeRemaining - 10)
                        timeRemaining = internalTimeRemaining
                    } label: {
                        VStack {
                            Image(systemName: "minus.circle.fill")
                                .font(.title)
                            Text("-10s")
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                    
                    Button {
                        dismiss()
                    } label: {
                        VStack {
                            Image(systemName: "forward.fill")
                                .font(.title)
                            Text("Skip")
                                .font(.caption2)
                        }
                        .foregroundStyle(.green)
                    }
                    
                    Button {
                        internalTimeRemaining += 10
                        timeRemaining = internalTimeRemaining
                    } label: {
                        VStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                            Text("+10s")
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                
                Button("End Set") {
                    dismiss()
                }
                .font(.headline)
                .foregroundStyle(.red)
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
            .padding(.horizontal, 32)
        }
        .onAppear {
            soundEffects.playTimedSetStart()
            startInternalTimer()
        }
        .onDisappear { timerTask?.cancel() }
    }
    
    private func startInternalTimer() {
        let end = Date().addingTimeInterval(internalTimeRemaining)
        timerTask = Task {
            while !Task.isCancelled && internalTimeRemaining > 0 {
                do {
                    try await Task.sleep(for: .milliseconds(100))
                } catch { break }
                let remaining = max(0, end.timeIntervalSinceNow)
                internalTimeRemaining = remaining
                timeRemaining = remaining
                
                // Countdown beeps at 3, 2, 1
                if remaining <= 3 && remaining > 0 && Int(remaining * 10) % 10 == 0 {
                    soundEffects.playCountdownBeep()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
            if internalTimeRemaining <= 0 {
                soundEffects.playTimedSetEnd()
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                try? await Task.sleep(for: .milliseconds(500))
                dismiss()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SetTimerOverlay(timeRemaining: .constant(30), totalTime: 45, exerciseName: "Plank")
}