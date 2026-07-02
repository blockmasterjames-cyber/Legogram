import SwiftUI

/// A gold trophy shown next to the username of a top-3 builder on the
/// leaderboard. Renders nothing for everyone else. Top-builder status is read
/// from the cached `TopBuilderRegistry` (fed by the leaderboard data), the
/// same pattern as `AdminBadge` / `FollowingBadge`.
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
