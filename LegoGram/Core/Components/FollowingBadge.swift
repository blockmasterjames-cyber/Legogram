import SwiftUI

/// A small "Following" indicator shown beside a username when the current user
/// follows that person. Suppress by passing the current user's own UID — the
/// badge hides itself when uid matches the signed-in user.
struct FollowingBadge: View {
    let uid: String

    @ObservedObject private var registry = FollowingRegistry.shared
    @ObservedObject private var userSession = UserSession.shared

    var body: some View {
        if uid != userSession.uid && registry.isFollowing(uid) {
            Image(systemName: "person.fill.checkmark")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.successGreen)
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(Color.successGreen.opacity(0.15))
                .cornerRadius(5)
        }
    }
}
