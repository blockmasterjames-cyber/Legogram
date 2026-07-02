import SwiftUI

/// A trophy flair shown next to a username when that user is one of the top 3
/// builders by total points. Renders nothing for everyone else. Top-3
/// membership is read from the cached `TopBuilderRegistry` (refreshed from the
/// leaderboard data), so no per-profile query is needed — same pattern as
/// `AdminBadge` / `FollowingBadge`.
struct TopBuilderBadge: View {
    let uid: String
    var size: CGFloat = 13

    @ObservedObject private var registry = TopBuilderRegistry.shared

    var body: some View {
        if registry.isTopBuilder(uid) {
            Image(systemName: "trophy.fill")
                .font(.system(size: size))
                .foregroundColor(.legoYellow)
                .accessibilityLabel("Top Builder")
        }
    }
}
