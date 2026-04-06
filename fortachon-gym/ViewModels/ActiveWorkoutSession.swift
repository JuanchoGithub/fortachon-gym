import SwiftUI
import FortachonCore

// MARK: - Global Active Workout Session Manager
// P0 Fix: Persists minimized workout state across tab navigation.
// This is elevated from ActiveWorkoutView so that when the user navigates
// to History, Profile, or any other tab, the minimized workout bar remains visible.

@Observable
class ActiveWorkoutSession {
    // MARK: - Published State
    
    /// Whether a workout is currently active at the app level.
    var isActive: Bool = false
    
    /// Whether the workout is in minimized (compact/pill) state.
    var isMinimized: Bool = false
    
    /// Elapsed time since workout started (updated every second).
    var elapsed: TimeInterval = 0
    
    /// Routine name displayed in the minimized bar.
    var routineName: String = ""
    
    /// Count of completed sets for quick display.
    var completedSets: Int = 0
    
    /// Total count of non-warmup sets.
    var totalSets: Int = 0
    
    // MARK: - Private
    
    private var timerTask: Task<Void, Never>?
    private var startTime: Date = .now
    
    // MARK: - Lifecycle
    
    func start(routineName: String) {
        self.isActive = true
        self.isMinimized = false
        self.elapsed = 0
        self.routineName = routineName
        self.startTime = Date()
        startTimer()
    }
    
    func minimize() {
        withAnimation(.spring()) {
            isMinimized = true
        }
    }
    
    func expand() {
        withAnimation(.spring()) {
            isMinimized = false
        }
    }
    
    func end() {
        stopTimer()
        withAnimation(.spring()) {
            isActive = false
            isMinimized = false
            elapsed = 0
            routineName = ""
            completedSets = 0
            totalSets = 0
        }
    }
    
    func updateProgress(completed: Int, total: Int) {
        completedSets = completed
        totalSets = total
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { @MainActor [start = self.startTime] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(1)) } catch { break }
                if !Task.isCancelled {
                    self.elapsed = Date().timeIntervalSince(start)
                }
            }
        }
    }
    
    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }
}