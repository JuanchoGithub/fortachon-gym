import Foundation
import AVFoundation
import Observation

/// Service for playing workout sound effects using AVAudioPlayer.
/// Generates tones programmatically — zero external dependencies.
@Observable
@MainActor
final class SoundEffectsService {
    
    // MARK: - State
    
    var isEnabled: Bool = true
    
    // MARK: - Dependencies
    
    private var audioPlayer: AVAudioPlayer?
    
    // MARK: - System Sounds
    
    /// Play a single beep sound (system sound 1070 — short tone).
    func playBeep() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1070)
    }
    
    /// Play a short blip for button tap feedback.
    func playBlip() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1104)
    }
    
    // MARK: - Set Complete
    
    /// Play a set-complete sound — a single ascending beep.
    func playSetComplete() {
        guard isEnabled else { return }
        playTone(frequency: 880, duration: 0.15)
    }
    
    // MARK: - Rest Timer
    
    /// Play a single countdown beep (used for 3, 2, 1 countdown).
    func playCountdownBeep() {
        guard isEnabled else { return }
        playTone(frequency: 660, duration: 0.1)
    }
    
    /// Play rest timer end alarm — three quick beeps.
    func playRestTimerEnd() {
        guard isEnabled else { return }
        playToneSequence(frequencies: [880, 880, 880], duration: 0.12, interval: 0.15)
    }
    
    // MARK: - Timed Set
    
    /// Play timed set start sound — two ascending beeps.
    func playTimedSetStart() {
        guard isEnabled else { return }
        playToneSequence(frequencies: [440, 660], duration: 0.15, interval: 0.2)
    }
    
    /// Play timed set end sound — three descending beeps.
    func playTimedSetEnd() {
        guard isEnabled else { return }
        playToneSequence(frequencies: [880, 660, 440], duration: 0.15, interval: 0.15)
    }
    
    // MARK: - PR Celebration
    
    /// Play PR celebration sound — ascending arpeggio.
    func playPRCelebration() {
        guard isEnabled else { return }
        playToneSequence(frequencies: [523, 659, 784, 1047], duration: 0.2, interval: 0.15)
    }
    
    // MARK: - Tone Generation
    
    /// Play a single tone at the given frequency.
    private func playTone(frequency: Double, duration: TimeInterval) {
        let sampleRate: Double = 44100
        let samples = Int(sampleRate * duration)
        var data = Data()
        
        for i in 0..<samples {
            let t = Double(i) / sampleRate
            let value = sin(2.0 * .pi * frequency * t)
            let int16Value = Int16(value * 32767.0)
            data.append(withUnsafeBytes(of: int16Value.littleEndian) { Data($0) })
        }
        
        let format = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        )
        
        guard let format = format,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples)) else { return }
        
        buffer.frameLength = AVAudioFrameCount(samples)
        let channelBuffer = buffer.int16ChannelData![0]
        
        data.withUnsafeBytes { rawPointer in
            let typedPointer = rawPointer.bindMemory(to: Int16.self)
            channelBuffer.initialize(from: typedPointer.baseAddress!, count: samples)
        }
        
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.volume = 0.5
            audioPlayer?.play()
        } catch {
            // Fallback to system sound
            AudioServicesPlaySystemSound(1070)
        }
    }
    
    /// Play a sequence of tones.
    private func playToneSequence(frequencies: [Double], duration: TimeInterval, interval: TimeInterval) {
        Task {
            for freq in frequencies {
                playTone(frequency: freq, duration: duration)
                try? await Task.sleep(for: .milliseconds(Int(interval * 1000)))
            }
        }
    }
}