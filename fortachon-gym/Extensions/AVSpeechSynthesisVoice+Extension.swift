import AVFAudio
import Foundation

extension AVSpeechSynthesisVoice {
    var voiceURI: String {
        if #available(iOS 16.0, *) {
            return self.identifier
        } else {
            return "\(self.name)-\(self.language)"
        }
    }
}
