import Foundation
import UIKit

/// Manages screen wake lock behavior to prevent the screen from dimming during workouts
@MainActor
final class ScreenWakeManager: ObservableObject {
    @Published var isAwake: Bool = false
    
    @MainActor static let shared = ScreenWakeManager()
    
    private init() {}
    
    func activate() {
        guard !isAwake else { return }
        UIApplication.shared.isIdleTimerDisabled = true
        isAwake = true
    }
    
    func deactivate() {
        guard isAwake else { return }
        UIApplication.shared.isIdleTimerDisabled = false
        isAwake = false
    }
    
    func toggle(_ enabled: Bool) {
        if enabled {
            activate()
        } else {
            deactivate()
        }
    }
}