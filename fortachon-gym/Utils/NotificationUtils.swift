import Foundation
import UserNotifications
import UIKit

/// Utility for managing notification permissions and settings
final class NotificationUtils {
    
    /// Current notification permission status
    static var currentStatus: UNAuthorizationStatus {
        get async {
            await withCheckedContinuation { continuation in
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    continuation.resume(returning: settings.authorizationStatus)
                }
            }
        }
    }
    
    /// Request notification permission from the user
    @MainActor
    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
        } catch {
            return false
        }
    }
    
    /// Check if notifications are currently enabled
    @MainActor
    static func areNotificationsEnabled() async -> Bool {
        let status = await currentStatus
        return status == .authorized || status == .provisional
    }
    
    /// Open app settings so user can enable notifications
    @MainActor
    static func openNotificationSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsUrl)
    }
    
    /// Get a human-readable status description
    static func statusDescription(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "Notifications have not been requested yet"
        case .denied:
            return "Notifications are blocked. Enable them in Settings."
        case .authorized:
            return "Notifications are enabled"
        case .provisional:
            return "Notifications are enabled (quiet delivery)"
        case .ephemeral:
            return "Notifications are temporarily enabled"
        @unknown default:
            return "Unknown notification status"
        }
    }
}