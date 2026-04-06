import Foundation
import UserNotifications

/// Manages push notification permissions and local notifications for BrickFeed.
/// Sends local notifications for likes, comments, and follows.
final class NotificationManager: ObservableObject {

    static let shared = NotificationManager()
    private init() {}

    @Published var notificationsEnabled: Bool = false

    // MARK: - Permission Request

    /// Call this after onboarding to request notification permission.
    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run { notificationsEnabled = granted }
            if granted {
                print("[NotificationManager] Notifications authorized.")
            }
        } catch {
            print("[NotificationManager] Permission error: \(error)")
        }
    }

    /// Check current authorization status.
    func checkPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            notificationsEnabled = settings.authorizationStatus == .authorized
        }
    }

    // MARK: - Local Notifications

    func sendLikeNotification(postOwnerUsername: String) {
        guard UserDefaults.standard.bool(forKey: "settings_notifications") else { return }
        let content = UNMutableNotificationContent()
        content.title = "Someone liked your build! ❤️"
        content.body  = "Your LEGO build just got a new like. Keep building!"
        content.sound = .default
        scheduleNotification(id: "like-\(UUID().uuidString)", content: content, delay: 1)
    }

    func sendCommentNotification(postOwnerUsername: String) {
        guard UserDefaults.standard.bool(forKey: "settings_notifications") else { return }
        let content = UNMutableNotificationContent()
        content.title = "New comment on your build! 💬"
        content.body  = "Someone commented on your LEGO build. Go check it out!"
        content.sound = .default
        scheduleNotification(id: "comment-\(UUID().uuidString)", content: content, delay: 1)
    }

    func sendFollowNotification(from followerUsername: String) {
        guard UserDefaults.standard.bool(forKey: "settings_notifications") else { return }
        let content = UNMutableNotificationContent()
        content.title = "New follower! 🧱"
        content.body  = "@\(followerUsername) is now following your builds!"
        content.sound = .default
        scheduleNotification(id: "follow-\(UUID().uuidString)", content: content, delay: 1)
    }

    private func scheduleNotification(id: String, content: UNMutableNotificationContent, delay: TimeInterval) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[NotificationManager] Schedule error: \(error)")
            }
        }
    }
}
