import SwiftUI
import FortachonCore
import Combine

/// A card view for timed exercises (planks, holds, etc.) with start/stop/reset controls.
struct TimedExerciseCard: View {
    let exercise: ExerciseM
    let idx: Int
    let existingSets: [PerformedSetM]
    let onAddSet: (Int) -> Void  // elapsed seconds
    
    @State private var elapsed: TimeInterval = 0
    @State private var isRunning = false
    @State private var timerCancellable: AnyCancellable?
    
    // P2: Timed set start countdown (3-2-1)
    @State private var isCountingDown = false
    @State private var countdownValue = 3
    @State private var countdownTask: Task<Void, Never>?
    
    // Sound effects
    @State private var soundEffects = SoundEffectsService()
    
    enum TimerState {
        case idle, countdown, running, completed
    }
    
    private var timerState: TimerState {
        if isCountingDown { return .countdown }
        if isRunning { return .running }
        if elapsed > 0 { return .completed }
        return .idle
    }
    
    private var timedSets: [PerformedSetM] {
        existingSets.filter { SetType(rawValue: $0.setTypeStr) == .timed }
    }
    
    private var stateColor: Color {
        switch timerState {
        case .idle: return .secondary
        case .countdown: return .orange
        case .running: return .green
        case .completed: return .blue
        }
    }
    
    private var stateIcon: String {
        switch timerState {
        case .idle: return "timer"
        case .countdown: return "timer.circle"
        case .running: return "timer.circle.fill"
        case .completed: return "checkmark.circle.fill"
        }
    }
    
    // Countdown animation scale
    private var countdownScale: Double {
        switch countdownValue {
        case 3: return 1.0
        case 2: return 0.9
        case 1: return 0.8
        default: return 1.0
        }
    }
    
    // MARK: - Countdown Functions
    
    /// Begin 3-2-1 countdown before starting the exercise timer
    private func beginCountdown() {
        isCountingDown = true
        countdownValue = 3
        soundEffects.playCountdownBeep()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        countdownTask = Task {
            while countdownValue > 0 && !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                await MainActor.run {
                    countdownValue -= 1
                    if countdownValue > 0 {
                        soundEffects.playCountdownBeep()
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } else {
                        // Countdown complete — start the exercise timer
                        isCountingDown = false
                        soundEffects.playTimedSetStart()
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        startTimer()
                    }
                }
            }
        }
    }
    
    /// Cancel the countdown and return to idle state
    private func cancelCountdown() {
        countdownTask?.cancel()
        countdownTask = nil
        isCountingDown = false
        countdownValue = 3
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: stateIcon)
                    .font(.title2)
                    .foregroundStyle(stateColor)
                VStack(alignment: .leading) {
                    Text(exercise.name)
                        .font(.headline)
                    if !timedSets.isEmpty {
                        Text("\(timedSets.count) set(s) logged")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Ready to start")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                // Timer display — show countdown overlay or elapsed time
                if timerState == .countdown {
                    Text("\(countdownValue)")
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundStyle(.orange)
                        .scaleEffect(countdownScale + 0.2)
                        .animation(.easeOut(duration: 0.3), value: countdownValue)
                } else {
                    Text(formatTime(elapsed))
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundStyle(stateColor)
                        .monospacedDigit()
                }
            }
            
            // Controls
            HStack(spacing: 16) {
                if timerState == .idle {
                    Button(action: beginCountdown) {
                        Label("Start", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundStyle(.white)
                            .background(Color.green)
                            .clipShape(Capsule())
                    }
                } else if timerState == .countdown {
                    Button(action: cancelCountdown) {
                        Label("Cancel", systemImage: "xmark")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundStyle(.white)
                            .background(Color.orange)
                            .clipShape(Capsule())
                    }
                } else if isRunning {
                    Button(action: stopTimer) {
                        Label("Stop", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundStyle(.white)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }
                
                if elapsed > 0 && !isRunning && timerState != .countdown {
                    Button(action: resetTimer) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundStyle(.white)
                            .background(Color.gray)
                            .clipShape(Capsule())
                    }
                    
                    Button(action: saveSet) {
                        Label("Save", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundStyle(.white)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                }
            }
            
            // Previous sets
            if !timedSets.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("Previous Sets")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(Array(timedSets.enumerated()), id: \.offset) { i, set in
                        HStack {
                            Text("Set \(i + 1)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(formatTime(Double(set.setTime ?? 0)))
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.primary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .onDisappear { stopTimer() }
    }
    
    private func startTimer() {
        isRunning = true
        timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                elapsed += 0.1
            }
    }
    
    private func stopTimer() {
        isRunning = false
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    private func resetTimer() {
        stopTimer()
        elapsed = 0
    }
    
    private func saveSet() {
        let seconds = Int(elapsed)
        guard seconds > 0 else { return }
        onAddSet(seconds)
        elapsed = 0
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        let tenths = Int((seconds.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", mins, secs, tenths)
    }
}