import SwiftUI

// MARK: - Inline Rest Timer Overlay (P0: Replaces fullScreenCover)
/// A compact rest timer that overlays the workout view without losing context of the exercise list.

struct InlineRestTimerOverlay: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var timeRemaining: TimeInterval
    let totalTime: TimeInterval
    let exerciseName: String
    let onSkip: () -> Void
    let onDismiss: () -> Void
    
    @State private var timerTask: Task<Void, Never>?
    @State private var internalTimeRemaining: TimeInterval
    @State private var soundEffects = SoundEffectsService()
    @State private var isPaused: Bool = false
    
    // Rest time presets
    let presets: [(label: String, seconds: Int)] = [
        ("30s", 30), ("60s", 60), ("90s", 90), ("2m", 120), ("3m", 180)
    ]
    
    init(
        timeRemaining: Binding<TimeInterval>,
        totalTime: TimeInterval,
        exerciseName: String = "",
        onSkip: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self._timeRemaining = timeRemaining
        self.totalTime = totalTime
        self.exerciseName = exerciseName
        self.onSkip = onSkip
        self.onDismiss = onDismiss
        _internalTimeRemaining = State(initialValue: timeRemaining.wrappedValue)
    }
    
    var progress: Double {
        guard totalTime > 0 else { return 0 }
        return 1.0 - (internalTimeRemaining / totalTime)
    }
    
    var body: some View {
        ZStack {
            // Semi-transparent backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            
            VStack(spacing: 0) {
                // Spacer pushes timer to bottom
                Spacer()
                
                // Timer card anchored at bottom
                VStack(spacing: 16) {
                    // Exercise name header
                    if !exerciseName.isEmpty {
                        Text(exerciseName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                    
                    Text("Rest Time")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    // Time display
                    Text(internalTimeRemaining.formattedAsTimer)
                        .font(.system(size: 56, weight: .bold, design: .monospaced))
                        .foregroundStyle(internalTimeRemaining <= 3 ? .orange : .primary)
                        .animation(.easeInOut, value: internalTimeRemaining)
                    
                    // Simple progress bar
                    if totalTime > 0 {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 6)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .cyan],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * progress, height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                    
                    // Rest time presets
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(presets, id: \.seconds) { preset in
                                Button {
                                    internalTimeRemaining = TimeInterval(preset.seconds)
                                    timeRemaining = internalTimeRemaining
                                } label: {
                                    Text(preset.label)
                                        .font(.caption.bold())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
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
                    
                    // Controls row
                    HStack(spacing: 20) {
                        Button {
                            internalTimeRemaining = max(0, internalTimeRemaining - 10)
                            timeRemaining = internalTimeRemaining
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        .disabled(isPaused)
                        
                        // Pause/Resume button
                        Button {
                            if isPaused {
                                isPaused = false
                                startInternalTimer()
                            } else {
                                timerTask?.cancel()
                                isPaused = true
                            }
                        } label: {
                            Image(systemName: isPaused ? "play.circle.fill" : "pause.circle.fill")
                                .font(.title2)
                                .foregroundStyle(isPaused ? .orange : .secondary)
                        }
                        
                        // Skip button
                        Button {
                            onSkip()
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
                    
                    // Paused indicator
                    if isPaused {
                        Text("Timer Paused")
                            .font(.caption.bold())
                            .foregroundStyle(.orange)
                    }
                }
                .padding(24)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
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
                onDismiss()
            }
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        InlineRestTimerOverlay(
            timeRemaining: .constant(60),
            totalTime: 90,
            exerciseName: "Bench Press",
            onSkip: {},
            onDismiss: {}
        )
    }
}