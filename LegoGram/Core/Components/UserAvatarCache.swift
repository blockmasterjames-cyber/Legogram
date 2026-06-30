import SwiftUI

/// A tiny shared cache mapping a user UID → their avatar URL.
///
/// Several places need to show a user's profile picture but only have that
/// user's UID (e.g. older comments stored with an empty `avatar_url`, or
/// `ConversationRow` which only knows `otherUserId`). Rather than each row
/// firing its own `fetchUser` repeatedly on every redraw, they ask this cache.
///
/// The first request for a given UID triggers a one-time
/// `FirebaseService.shared.fetchUser` and stores the resulting `avatarURL`;
/// every subsequent request (and every re-render after the fetch lands) reads
/// straight from the published dictionary. In-flight fetches are deduped by UID
/// so repeated rows / scrolling never refetch the same user.
///
/// Shared via `UserAvatarCache.shared`, matching the singleton pattern used by
/// the app's other shared stores (`PostStore.shared`, `DMStore.shared`).
@MainActor
final class UserAvatarCache: ObservableObject {

    // MARK: - Singleton
    static let shared = UserAvatarCache()

    // MARK: - Published State

    /// uid → resolved avatar URL. An entry of `""` means "fetched, but this user
    /// has no avatar" — kept so we don't refetch users who simply lack a photo.
    @Published private(set) var urls: [String: String] = [:]

    // MARK: - Private State

    /// UIDs with a fetch currently in flight, so repeated rows / redraws don't
    /// kick off duplicate fetches for the same user.
    private var inFlight: Set<String> = []

    private init() {}

    // MARK: - Lookup

    /// Returns the cached avatar URL for `uid` if it is already known; otherwise
    /// triggers a one-time fetch (deduped by UID) and returns `nil` for now. When
    /// the fetch lands, `urls` publishes and any observing view re-renders and
    /// then receives the resolved URL.
    ///
    /// A returned value may be `""` (user has no avatar) — callers can pass it
    /// straight into `UserAvatar`, which shows its initial-letter fallback for
    /// empty/nil URLs.
    func avatarURL(for uid: String) -> String? {
        guard !uid.isEmpty else { return nil }

        if let cached = urls[uid] {
            return cached
        }

        // Not cached yet — start a single fetch for this UID.
        guard !inFlight.contains(uid) else { return nil }
        inFlight.insert(uid)

        Task {
            do {
                let user = try await FirebaseService.shared.fetchUser(userId: uid)
                urls[uid] = user.avatarURL
            } catch {
                // Cache an empty string on failure so we don't hammer Firestore
                // on every redraw; the initial-letter fallback shows meanwhile.
                urls[uid] = ""
            }
            inFlight.remove(uid)
        }

        return nil
    }
}
