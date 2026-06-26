import Foundation

/// Session-wide cache of admin user IDs, used to render the verified-style
/// admin badge next to usernames without reading `admins/{uid}` per username.
///
/// The set is fetched once per launch (and on demand) from the `admins`
/// collection — the SAME authoritative, console-only source used for the admin
/// gate. Views ask `isAdmin(uid)` against the in-memory cache.
@MainActor
final class AdminRegistry: ObservableObject {

    static let shared = AdminRegistry()

    /// The cached set of admin uids. Published so badge views refresh when it loads.
    @Published private(set) var adminUids: Set<String> = []

    private init() {}

    /// Loads the admin uid set from Firestore. Safe to call on every launch.
    func refresh() async {
        adminUids = await FirebaseService.shared.fetchAdminUids()
    }

    /// Whether the given uid belongs to an admin (per the cached set).
    func isAdmin(_ uid: String) -> Bool {
        guard !uid.isEmpty else { return false }
        return adminUids.contains(uid)
    }
}
