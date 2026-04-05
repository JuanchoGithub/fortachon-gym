import SwiftUI
import Foundation
import FortachonCore

// MARK: - Rest Times (matching web version)

struct RestTimes {
    var normal: Int = 90
    var warmup: Int = 60
    var drop: Int = 30
    var timed: Int = 10
    var effort: Int = 90
    var failure: Int = 300
}

// MARK: - View Helpers

extension TimeInterval {
    var formattedAsTimer: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedAsWorkout: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}