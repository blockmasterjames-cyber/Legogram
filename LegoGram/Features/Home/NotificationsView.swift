import SwiftUI
import FirebaseFirestore
import FirebaseAuth

/// Shows in-app notifications: likes, comments, and follows.
/// Reads from users/{uid}/notifications in Firestore.
struct NotificationsView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var notifications: [AppNotification] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView().tint(.legoYellow).scaleEffect(1.4)
                        Text("Loading notifications...")
                            .font(.legoBody).foregroundColor(.secondaryText)
                    }
                } else if notifications.isEmpty {
                    emptyState
                } else {
                    notificationsList
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.cardBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.legoYellow)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !notifications.isEmpty {
                        Button("Mark All Read") {
                            markAllRead()
                        }
                        .font(.legoCaption)
                        .foregroundColor(.legoYellow)
                    }
                }
            }
        }
        .task { await loadNotifications() }
        .preferredColorScheme(.dark)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 64))
                .foregroundColor(.secondaryText)

            Text("No notifications yet!")
                .font(.legoCardTitle)
                .foregroundColor(.lightText)

            Text("No notifications yet! Start posting and connecting with builders 🧱")
                .font(.legoBody)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Notifications List

    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(notifications) { notif in
                    notificationRow(notif)
                }
            }
            .background(Color.cardBackground)
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Color.clear.frame(height: 60)
        }
    }

    // MARK: - Notification Row

    private func notificationRow(_ notif: AppNotification) -> some View {
        HStack(spacing: 14) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(notif.iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: notif.icon)
                    .font(.system(size: 20))
                    .foregroundColor(notif.iconColor)
            }

            // Message + time
            VStack(alignment: .leading, spacing: 4) {
                Text(notif.message)
                    .font(.legoBody)
                    .foregroundColor(notif.isRead ? .secondaryText : .lightText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(notif.timeAgo)
                    .font(.legoCaption)
                    .foregroundColor(.secondaryText)
            }

            Spacer()

            // Unread dot
            if !notif.isRead {
                Circle()
                    .fill(Color.legoRed)
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(notif.isRead ? Color.cardBackground : Color.legoYellow.opacity(0.04))
    }

    // MARK: - Data Loading

    private func loadNotifications() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        do {
            notifications = try await FirebaseService.shared.fetchNotifications(userId: uid)
            // Mark all as read after viewing
            try? await FirebaseService.shared.markAllNotificationsRead(userId: uid)
        } catch {
            print("[NotificationsView] Load error: \(error)")
        }
        isLoading = false
    }

    private func markAllRead() {
        notifications = notifications.map { var n = $0; n.isRead = true; return n }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Task { try? await FirebaseService.shared.markAllNotificationsRead(userId: uid) }
    }
}

#Preview {
    NotificationsView()
}
