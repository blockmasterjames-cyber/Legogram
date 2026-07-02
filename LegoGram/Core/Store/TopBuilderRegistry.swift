import Foundation

/// Session-wide cache of the top-3 user IDs by `total_points`, used to render
/// the Top Builder badge next to usernames without a per-profile query.
/// Mirror of AdminRegistry's pattern, fed by the leaderboard data.
///
/// Populated whenever the Leaderboard loads (it already has the ranked users)
/// and, as a fallback, by a lightweight top-3 fetch the first time a profile
/// needs it before the Leaderboard tab has been opened.
@MainActor
final class TopBuilderRegistry: ObservableObject {

    static let shared = TopBuilderRegistry()
    private init() {}

    /// The cached top-3 uids. Published so badge views refresh when it loads.
    @Published private(set) var topBuilderUids: Set<String> = []

    private var hasLoaded = false

    /// Refreshes the cache from an already-ranked (points-descending)
    /// leaderboard result — no extra query. Zero-point users are excluded so a
    /// brand-new community doesn't badge arbitrary accounts.
    func update(fromRanked users: [User]) {
        topBuilderUids = Set(users.prefix(3).filter { $0.totalPoints > 0 }.map(\.id))
        hasLoaded = true
    }

    /// One-per-session fallback load for screens that can render before the
    /// Leaderboard has populated the cache (e.g. a profile opened first).
    /// Fetches only the top 3; a failed fetch leaves `hasLoaded` false so the
    /// next profile visit retries.
    func refreshIfNeeded() async {
        guard !hasLoaded else { return }
        guard let top = try? await FirebaseService.shared.fetchLeaderboard(limit: 3) else { return }
        update(fromRanked: top)
    }

    /// Whether the given uid is one of the top 3 builders (per the cached set).
    func isTopBuilder(_ uid: String) -> Bool {
        guard !uid.isEmpty else { return false }
        return topBuilderUids.contains(uid)
    }
}
