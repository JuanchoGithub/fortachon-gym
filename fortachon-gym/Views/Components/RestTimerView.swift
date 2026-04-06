import SwiftUI

// MARK: - Rest Timer Overlay View

struct RestTimerOverlay: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var timeRemaining: TimeInterval
    let totalTime: TimeInterval
    
    @State private var timerTask: Task<Void, Never>?
    @State private var internalTimeRemaining: TimeInterval
    @State private var soundEffects = SoundEffectsService()
    // Phase 4: Pause/resume support
    @State private var isPaused: Bool = false
    @State private var pausedAt: TimeInterval = 0
    
    // Rest time presets
    let presets: [(label: String, seconds: Int)] = [
        ("30s", 30), ("60s", 60), ("90s", 90), ("2m", 120), ("3m", 180), ("5m", 300)
    ]
    
    init(timeRemaining: Binding<TimeInterval>, totalTime: TimeInterval) {
        self._timeRemaining = timeRemaining
        self.totalTime = totalTime
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
            
            VStack(spacing: 24) {
                Text("Rest Time")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                // Circular progress
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 8)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                    
                    Text(internalTimeRemaining.formattedAsTimer)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                }
                
                // Rest time presets
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(presets, id: \.seconds) { preset in
                            Button {
                                internalTimeRemaining = TimeInterval(preset.seconds)
                                timeRemaining = internalTimeRemaining
                            } label: {
                                Text(preset.label)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Int(internalTimeRemaining) == preset.seconds ? Color.blue : Color(.systemGray5),
                                        in: Capsule()
                                    )
                                    .foregroundStyle(
                                        Int(internalTimeRemaining) == preset.seconds ? .white : .secondary
                                    )
                            }
                        }
                    }
                }
                
                HStack(spacing: 16) {
                    Button {
                        internalTimeRemaining = max(0, internalTimeRemaining - 10)
                        timeRemaining = internalTimeRemaining
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .disabled(isPaused)
                    
                    // Phase 4: Pause/Resume button
                    Button {
                        if isPaused {
                            // Resume: restart timer with remaining time
                            isPaused = false
                            startInternalTimerFromRemaining()
                        } else {
                            // Pause: cancel timer, save current time
                            timerTask?.cancel()
                            pausedAt = internalTimeRemaining
                            isPaused = true
                        }
                    } label: {
                        Image(systemName: isPaused ? "play.circle.fill" : "pause.circle.fill")
                            .font(.title2)
                            .foregroundStyle(isPaused ? .orange : .secondary)
                    }
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                    }
                    .disabled(isPaused)
                    
                    Button {
                        internalTimeRemaining += 10
                        timeRemaining = internalTimeRemaining
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .disabled(isPaused)
                }
                
                // Phase 4: Show paused indicator
                if isPaused {
                    Text("Timer Paused")
                        .font(.headline)
                        .foregroundStyle(.orange)
                }
                
                Button("Skip Rest") {
                    dismiss()
                }
                .font(.headline)
                .foregroundStyle(.secondary)
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 40)
        }
        .onAppear { startInternalTimer() }
        .onDisappear { timerTask?.cancel() }
    }
    
    private func startInternalTimer() {
        let end = Date().addingTimeInterval(internalTimeRemaining)
        timerTask = Task {
            while !Task.isCancelled && internalTimeRemaining > 0 && !isPaused {
                do {
                    try await Task.sleep(for: .milliseconds(100))
                } catch { break }
                if isPaused { break }
                let remaining = max(0, end.timeIntervalSinceNow)
                internalTimeRemaining = remaining
                timeRemaining = remaining
                
                // Countdown beeps at 3, 2, 1
                if remaining <= 3 && remaining > 0 {
                    let wholeSeconds = Int(remaining)
                    let prevWholeSeconds = Int(remaining + 0.1)
                    if wholeSeconds != prevWholeSeconds && wholeSeconds <= 3 && wholeSeconds > 0 {
                        soundEffects.playCountdownBeep()
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }
            }
            if internalTimeRemaining <= 0 && !isPaused {
                soundEffects.playRestTimerEnd()
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                try? await Task.sleep(for: .milliseconds(500))
                dismiss()
            }
        }
    }
    
    // Phase 4: Resume timer from paused state
    private func startInternalTimerFromRemaining() {
        let end = Date().addingTimeInterval(internalTimeRemaining)
        timerTask = Task {
            while !Task.isCancelled && internalTimeRemaining > 0 && !isPaused {
                do {
                    try await Task.sleep(for: .milliseconds(100))
                } catch { break }
                if isPaused { break }
                let remaining = max(0, end.timeIntervalSinceNow)
                internalTimeRemaining = remaining
                timeRemaining = remaining
                
                // Countdown beeps at 3, 2, 1
                if remaining <= 3 && remaining > 0 {
                    let wholeSeconds = Int(remaining)
                    let prevWholeSeconds = Int(remaining + 0.1)
                    if wholeSeconds != prevWholeSeconds && wholeSeconds <= 3 && wholeSeconds > 0 {
                        soundEffects.playCountdownBeep()
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }
            }
            if internalTimeRemaining <= 0 && !isPaused {
                soundEffects.playRestTimerEnd()
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                try? await Task.sleep(for: .milliseconds(500))
                dismiss()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RestTimerOverlay(timeRemaining: .constant(60), totalTime: 90)
}
