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
    
    enum TimerState {
        case idle, running, completed
    }
    
    private var timerState: TimerState {
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
        case .running: return .green
        case .completed: return .blue
        }
    }
    
    private var stateIcon: String {
        switch timerState {
        case .idle: return "timer"
        case .running: return "timer.circle.fill"
        case .completed: return "checkmark.circle.fill"
        }
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
                // Timer display
                Text(formatTime(elapsed))
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundStyle(stateColor)
                    .monospacedDigit()
            }
            
            // Controls
            HStack(spacing: 16) {
                if !isRunning {
                    Button(action: startTimer) {
                        Label(isRunning ? "Pause" : "Start", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundStyle(.white)
                            .background(Color.green)
                            .clipShape(Capsule())
                    }
                    .disabled(isRunning)
                } else {
                    Button(action: stopTimer) {
                        Label("Stop", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundStyle(.white)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }
                
                if elapsed > 0 && !isRunning {
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