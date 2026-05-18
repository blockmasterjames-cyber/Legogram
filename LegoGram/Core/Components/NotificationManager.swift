import Foundation
import UserNotifications

/// Manages push notification permissions and local notifications for BrickFeed.
///
/// Apple Guideline 4.5.4 compliance: NO notification permission prompt and NO
/// notification scheduling may occur unless the user has explicitly opted in by
/// toggling the Settings → Push Notifications switch ON. Every call site that
/// could touch UNUserNotificationCenter logs through this manager so the Xcode
/// console makes it obvious WHEN (if ever) a prompt is requested.
final class NotificationManager: ObservableObject {

    static let shared = NotificationManager()
    private init() {}

    @Published var notificationsEnabled: Bool = false

    /// UserDefaults key controlled by the Settings → Push Notifications toggle.
    /// The toggle defaults to OFF and is the ONLY way to flip this to true.
    private let userToggleKey = "settings_notifications"

    private var userOptedIn: Bool {
        UserDefaults.standard.bool(forKey: userToggleKey)
    }

    // MARK: - Permission Request

    /// The ONLY function in the app that calls `requestAuthorization`. It must
    /// only be invoked from the Settings notifications toggle's onChange handler
    /// when the user flips the toggle from OFF to ON. Calling it from anywhere
    /// else (app launch, signup, login, onboarding) violates Guideline 4.5.4.
    func requestPermission() async {
        // Defensive guard: do not request unless the user toggle says ON.
        guard userOptedIn else {
            print("[NotificationManager] requestPermission() called but user toggle is OFF — aborting. No prompt will be shown.")
            return
        }
        print("[NotificationManager] requestPermission() — user toggle is ON, calling UNUserNotificationCenter.requestAuthorization NOW. This will show the system prompt.")
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run { notificationsEnabled = granted }
            print("[NotificationManager] requestAuthorization returned granted=\(granted)")
        } catch {
            print("[NotificationManager] Permission error: \(error)")
        }
    }

    /// Read-only check of the current iOS authorization status. Does NOT prompt.
    func checkPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            notificationsEnabled = settings.authorizationStatus == .authorized
        }
    }

    // MARK: - Local Notifications

    func sendLikeNotification(postOwnerUsername: String) {
        print("[NotificationManager] sendLikeNotification requested for \(postOwnerUsername)")
        guard userOptedIn else {
            print("[NotificationManager] sendLikeNotification skipped — user toggle is OFF.")
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "Someone liked your build! ❤️"
        content.body  = "Your LEGO build just got a new like. Keep building!"
        content.sound = .default
        scheduleNotification(id: "like-\(UUID().uuidString)", content: content, delay: 1)
    }

    func sendCommentNotification(postOwnerUsername: String) {
        print("[NotificationManager] sendCommentNotification requested for \(postOwnerUsername)")
        guard userOptedIn else {
            print("[NotificationManager] sendCommentNotification skipped — user toggle is OFF.")
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "New comment on your build! 💬"
        content.body  = "Someone commented on your LEGO build. Go check it out!"
        content.sound = .default
        scheduleNotification(id: "comment-\(UUID().uuidString)", content: content, delay: 1)
    }

    func sendFollowNotification(from followerUsername: String) {
        print("[NotificationManager] sendFollowNotification requested from \(followerUsername)")
        guard userOptedIn else {
            print("[NotificationManager] sendFollowNotification skipped — user toggle is OFF.")
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "New follower! 🧱"
        content.body  = "@\(followerUsername) is now following your builds!"
        content.sound = .default
        scheduleNotification(id: "follow-\(UUID().uuidString)", content: content, delay: 1)
    }

    /// Schedules a local notification ONLY after confirming both the user toggle
    /// is ON and the iOS authorization status is `.authorized`. The system
    /// authorization check prevents `.add(request)` from being called when iOS
    /// has no recorded authorization decision — that call can otherwise surface
    /// a permission prompt on newer iOS versions and is what Apple flagged.
    private func scheduleNotification(id: String, content: UNMutableNotificationContent, delay: TimeInterval) {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            guard settings.authorizationStatus == .authorized else {
                print("[NotificationManager] scheduleNotification \(id) skipped — iOS authorizationStatus=\(settings.authorizationStatus.rawValue) (not authorized). Not calling .add().")
                return
            }
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            print("[NotificationManager] scheduleNotification \(id) — iOS authorized, calling UNUserNotificationCenter.add() NOW.")
            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    print("[NotificationManager] Schedule error: \(error)")
                }
            }
        }
    }
}
