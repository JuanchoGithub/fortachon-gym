import SwiftUI

// MARK: - Inline Rest Timer Overlay (P0: Replaces fullScreenCover)
/// A compact rest timer that overlays the workout view without losing context of the exercise list.

struct InlineRestTimerOverlay: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var timeRemaining: TimeInterval
    @Binding var totalTime: TimeInterval
    let exerciseName: String
    let onSkip: () -> Void
    let onDismiss: () -> Void
    
    @State private var timerTask: Task<Void, Never>?
    @State private var internalTimeRemaining: TimeInterval
    @State private var internalTotalTime: TimeInterval
    @State private var soundEffects = SoundEffectsService()
    @State private var isPaused: Bool = false
    @State private var lastBeepSecond: Int = -1
    
    // Rest time presets
    let presets: [(label: String, seconds: Int)] = [
        ("30s", 30), ("60s", 60), ("90s", 90), ("2m", 120), ("3m", 180), ("5m", 300)
    ]
    
    init(
        timeRemaining: Binding<TimeInterval>,
        totalTime: Binding<TimeInterval>,
        exerciseName: String = "",
        onSkip: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self._timeRemaining = timeRemaining
        self._totalTime = totalTime
        self.exerciseName = exerciseName
        self.onSkip = onSkip
        self.onDismiss = onDismiss
        _internalTimeRemaining = State(initialValue: timeRemaining.wrappedValue)
        _internalTotalTime = State(initialValue: totalTime.wrappedValue)
    }
    
    var progress: Double {
        guard internalTotalTime > 0 else { return 0 }
        return 1.0 - (internalTimeRemaining / internalTotalTime)
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Semi-transparent backdrop - NO tap gesture to dismiss
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                
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
                        
                        // Circular progress with time display
                        ZStack {
                            // Background circle
                            Circle()
                                .stroke(Color(.systemGray5), lineWidth: 8)
                                .frame(width: 160, height: 160)
                            
                            // Progress circle
                            Circle()
                                .trim(from: 0, to: max(0.001, progress))
                                .stroke(
                                    LinearGradient(
                                        colors: timerColor,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .frame(width: 160, height: 160)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 0.1), value: progress)
                            
                            // Time display in center
                            Text(internalTimeRemaining.formattedAsTimer)
                                .font(.system(size: 40, weight: .bold, design: .monospaced))
                                .foregroundStyle(timerTextColor)
                        }
                        
                        // Rest time presets
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(presets, id: \.seconds) { preset in
                                    Button {
                                        selectPreset(preset.seconds)
                                    } label: {
                                        Text(preset.label)
                                            .font(.caption.bold())
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                selectedPreset == preset.seconds ? Color.blue : Color(.systemGray6),
                                                in: Capsule()
                                            )
                                            .foregroundStyle(
                                                selectedPreset == preset.seconds ? .white : .secondary
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        // Controls row
                        HStack(spacing: 24) {
                            // -10 seconds
                            Button {
                                adjustTime(-10)
                            } label: {
                                VStack(spacing: 2) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                    Text("10s")
                                        .font(.caption2)
                                }
                                .foregroundStyle(.secondary)
                            }
                            .disabled(isPaused)
                            
                            // Pause/Resume button
                            Button {
                                togglePause()
                            } label: {
                                Image(systemName: isPaused ? "play.circle.fill" : "pause.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(isPaused ? .orange : .blue)
                            }
                            
                            // Skip button
                            Button {
                                onSkip()
                            } label: {
                                VStack(spacing: 2) {
                                    Image(systemName: "forward.fill")
                                        .font(.title2)
                                    Text("Skip")
                                        .font(.caption2)
                                }
                                .foregroundStyle(.green)
                            }
                            .disabled(isPaused)
                            
                            // +10 seconds
                            Button {
                                adjustTime(10)
                            } label: {
                                VStack(spacing: 2) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                    Text("10s")
                                        .font(.caption2)
                                }
                                .foregroundStyle(.secondary)
                            }
                            .disabled(isPaused)
                        }
                        
                        // Paused indicator
                        if isPaused {
                            Label("Timer Paused", systemImage: "pause.fill")
                                .font(.caption.bold())
                                .foregroundStyle(.orange)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 12)
                                .background(Color.orange.opacity(0.15), in: Capsule())
                        }
                    }
                    .padding(24)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .onAppear { startInternalTimer() }
        .onDisappear { timerTask?.cancel() }
    }
    
    // MARK: - Computed Properties
    
    private var selectedPreset: Int? {
        presets.map(\.seconds).contains(Int(internalTotalTime)) ? Int(internalTotalTime) : nil
    }
    
    private var timerColor: [Color] {
        if internalTimeRemaining <= 3 {
            return [.orange, .red]
        } else if internalTimeRemaining <= 10 {
            return [.yellow, .orange]
        } else {
            return [.blue, .cyan]
        }
    }
    
    private var timerTextColor: Color {
        if internalTimeRemaining <= 3 {
            return .orange
        } else {
            return .primary
        }
    }
    
    // MARK: - Timer Controls
    
    private func selectPreset(_ seconds: Int) {
        // Cancel current timer
        timerTask?.cancel()
        
        // Update both remaining and total times
        internalTimeRemaining = TimeInterval(seconds)
        internalTotalTime = TimeInterval(seconds)
        timeRemaining = internalTimeRemaining
        totalTime = internalTotalTime
        
        // Restart timer if not paused
        if !isPaused {
            startInternalTimer()
        }
    }
    
    private func adjustTime(_ delta: Int) {
        let newTime = max(5, internalTimeRemaining + TimeInterval(delta))
        internalTimeRemaining = newTime
        timeRemaining = newTime
        
        // Also adjust total time to keep progress meaningful
        internalTotalTime = max(5, internalTotalTime + TimeInterval(delta))
        totalTime = internalTotalTime
        
        // Restart timer with new end time
        if !isPaused {
            startInternalTimer()
        }
    }
    
    private func togglePause() {
        if isPaused {
            isPaused = false
            lastBeepSecond = -1
            startInternalTimer()
        } else {
            timerTask?.cancel()
            isPaused = true
        }
    }
    
    private func startInternalTimer() {
        lastBeepSecond = -1
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
                let wholeSeconds = Int(remaining)
                if wholeSeconds <= 3 && wholeSeconds > 0 && wholeSeconds != lastBeepSecond {
                    lastBeepSecond = wholeSeconds
                    soundEffects.playCountdownBeep()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
            if internalTimeRemaining <= 0 && !isPaused {
                soundEffects.playRestTimerEnd()
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                try? await Task.sleep(for: .milliseconds(500))
                await MainActor.run {
                    onDismiss()
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        InlineRestTimerOverlay(
            timeRemaining: .constant(60),
            totalTime: .constant(90),
            exerciseName: "Bench Press",
            onSkip: {},
            onDismiss: {}
        )
    }
}
