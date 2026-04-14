import UserNotifications
import SwiftUI

// MARK: - Notification Service
// Handles local push notifications for matches and messages.
// In production, swap UNTimeIntervalNotificationTrigger for APNs remote triggers.

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    // MARK: - Permission

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error = error {
                print("[Notifications] Permission error: \(error.localizedDescription)")
            } else {
                print("[Notifications] Permission granted: \(granted)")
            }
        }
    }

    // MARK: - Match Notification

    func scheduleMatchNotification(matchName: String, cosmicScore: Int) {
        let content = UNMutableNotificationContent()
        content.title = "It's a cosmic match! ✦"
        content.body = "You and \(matchName) liked each other — \(cosmicScore)% compatibility. The stars aligned."
        content.sound = .default
        content.categoryIdentifier = "MATCH"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "match-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[Notifications] Match notification error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - New Message Notification

    func scheduleMessageNotification(senderName: String, preview: String) {
        let content = UNMutableNotificationContent()
        content.title = senderName
        content.body = preview
        content.sound = .default
        content.categoryIdentifier = "MESSAGE"

        // Small delay so the user has time to leave the app
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2.0, repeats: false)
        let request = UNNotificationRequest(
            identifier: "message-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[Notifications] Message notification error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Transit Alert Notification

    func scheduleTransitNotification(planet: String, description: String) {
        let content = UNMutableNotificationContent()
        content.title = "\(planet) transit active ✦"
        content.body = description
        content.sound = .default
        content.categoryIdentifier = "TRANSIT"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        let request = UNNotificationRequest(
            identifier: "transit-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}
