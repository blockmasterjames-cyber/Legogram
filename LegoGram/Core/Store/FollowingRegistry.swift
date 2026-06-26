import Foundation

/// UID-keyed cache of accounts the current user follows.
/// Populated at launch from Firestore and updated on every follow/unfollow action.
/// Mirror of AdminRegistry's pattern but for following state.
@MainActor
final class FollowingRegistry: ObservableObject {

    static let shared = FollowingRegistry()
    private init() {}

    @Published private(set) var followedIds: Set<String> = []

    func refresh(with ids: Set<String>) {
        followedIds = ids
    }

    func follow(uid: String) {
        followedIds.insert(uid)
    }

    func unfollow(uid: String) {
        followedIds.remove(uid)
    }

    func isFollowing(_ uid: String) -> Bool {
        followedIds.contains(uid)
    }
}
