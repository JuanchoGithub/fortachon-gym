import SwiftUI
import FortachonCore

/// Shared AudioCoach instance injected via environment.
/// Prevents per-view recreation that cuts off speech mid-announcement.
@Observable
@MainActor
class AudioCoachManager {
    let coach = AudioCoach()
    
    var isEnabled: Bool {
        get { coach.isEnabled }
        set { coach.isEnabled = newValue }
    }
    
    func announceWorkoutStart(routineName: String) {
        coach.announceWorkoutStart(routineName: routineName)
    }
    
    func announceSetComplete(exerciseName: String, setNumber: Int, weight: Double, reps: Int) {
        coach.announceSetComplete(exerciseName: exerciseName, setNumber: setNumber, weight: weight, reps: reps)
    }
}
