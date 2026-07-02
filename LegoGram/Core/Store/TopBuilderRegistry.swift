import Foundation

/// Session-wide cache of the top-3 user IDs by `total_points`, used to render
/// the Top Builder badge next to usernames/profiles without a per-profile
/// query. Mirror of AdminRegistry's pattern.
///
/// Populated from the already-ranked leaderboard data whenever the Leaderboard
/// screen loads, plus once at sign-in via a light top-3 query so profiles can
/// badge correctly before the Leaderboard tab has ever been opened.
@MainActor
final class TopBuilderRegistry: ObservableObject {

    static let shared = TopBuilderRegistry()
    private init() {}

    /// The cached top-3 uids. Published so badge views refresh when it loads.
    @Published private(set) var topBuilderIds: Set<String> = []

    /// Updates the cache from an already-fetched leaderboard result (sorted by
    /// `total_points` descending). Users with zero points are never badged, so
    /// a brand-new community doesn't crown three empty accounts.
    func refresh(withRanked users: [User]) {
        topBuilderIds = Set(users.prefix(3).filter { $0.totalPoints > 0 }.map { $0.id })
    }

    /// Fetches just the top 3 from Firestore (same ordered query the
    /// leaderboard uses, limited to 3). Safe to call on every sign-in.
    func refreshFromServer() async {
        if let top = try? await FirebaseService.shared.fetchLeaderboard(limit: 3) {
            refresh(withRanked: top)
        }
    }

    /// Whether the given uid is one of the top 3 builders (per the cached set).
    func isTopBuilder(_ uid: String) -> Bool {
        guard !uid.isEmpty else { return false }
        return topBuilderIds.contains(uid)
    }
}
