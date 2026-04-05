import Foundation
import AVFoundation
import Observation

/// Audio coach service that provides spoken workout cues using AVSpeechSynthesizer.
/// Marked @Observable so it can be injected into SwiftUI views.
@Observable
@MainActor
final class AudioCoach {
    // MARK: - State
    
    var isEnabled: Bool = true
    
    // MARK: - Dependencies
    
    private let synthesizer = AVSpeechSynthesizer()
    private let language: String
    
    // MARK: - Speech Configuration
    
    private let speechRate: Float = 0.5
    private let speechPitch: Float = 1.0
    
    // MARK: - Localization Strings
    
    private enum AudioCue {
        case workoutStart(String)
        case setComplete(String, Int, Double, Int)
        case pr(String, String, Double)
        case rest(Int)
        case custom(String)
        
        func localized(isSpanish: Bool) -> String {
            switch self {
            case .workoutStart(let name):
                return isSpanish ? "Iniciando entrenamiento: \(name)" : "Starting workout: \(name)"
            case .setComplete(let exercise, let set, let weight, let reps):
                let unit = isSpanish ? "kilos" : "kilos"
                return isSpanish
                    ? "\(exercise). Serie \(set). \(Int(weight)) \(unit), \(reps) repeticiones."
                    : "\(exercise). Set \(set). \(Int(weight)) \(unit), \(reps) reps."
            case .pr(let type, let exercise, let value):
                return isSpanish
                    ? "Nuevo récord! \(type) en \(exercise): \(Int(value))"
                    : "New personal record! \(type) in \(exercise): \(Int(value))"
            case .rest(let seconds):
                return isSpanish
                    ? "Descansa \(seconds) segundos"
                    : "Rest for \(seconds) seconds"
            case .custom(let msg):
                return msg
            }
        }
    }
    
    // MARK: - Init
    
    init() {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        self.language = languageCode == "es" ? "es-ES" : "en-US"
    }
    
    // MARK: - Public API
    
    /// Announce that a workout has started.
    func announceWorkoutStart(routineName: String) {
        guard isEnabled else { return }
        speak(AudioCue.workoutStart(routineName))
    }
    
    /// Announce that a set has been completed.
    func announceSetComplete(exerciseName: String, setNumber: Int, weight: Double, reps: Int) {
        guard isEnabled else { return }
        speak(AudioCue.setComplete(exerciseName, setNumber, weight, reps))
    }
    
    /// Announce a personal record.
    func announcePR(type: String, exerciseName: String, value: Double) {
        guard isEnabled else { return }
        speak(AudioCue.pr(type, exerciseName, value))
    }
    
    /// Announce rest period.
    func announceRest(restSeconds: Int) {
        guard isEnabled else { return }
        speak(AudioCue.rest(restSeconds))
    }
    
    /// Generic speak method for custom messages.
    func speak(_ message: String) {
        guard !message.isEmpty else { return }
        let utterance = AVSpeechUtterance(string: message)
        utterance.voice = AVSpeechSynthesisVoice(identifier: language)
        utterance.rate = speechRate
        utterance.pitchMultiplier = speechPitch
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }
    
    // MARK: - Private Helpers
    
    private func speak(_ cue: AudioCue) {
        let isSpanish = language.hasPrefix("es")
        let text = cue.localized(isSpanish: isSpanish)
        speak(text)
    }
}