import SwiftUI
import Foundation

/// PostStore is the single source of truth for posts, comments, likes, blocks, and reports.
@MainActor
final class PostStore: ObservableObject {

    // MARK: - Singleton
    static let shared = PostStore()

    // MARK: - Published State

    /// All posts in the feed, newest first.
    @Published var posts: [LegoPost] = []

    /// Photos for posts keyed by post ID (in-memory; Firebase Storage in Sprint 4).
    @Published var postImages: [String: UIImage] = [:]

    /// Local video file URLs for video posts keyed by post ID.
    @Published var postVideoURLs: [String: URL] = [:]

    /// IDs of posts the current user has liked.
    @Published var likedPostIDs: Set<String> = []

    /// Comments keyed by post ID.
    @Published var comments: [String: [Comment]] = [:]

    /// Usernames the current user has blocked (kept in sync with `blockedUserIDs`
    /// — content is keyed by username in some places, by userId in others, so we
    /// filter on both for safety).
    @Published var blockedUsers: Set<String> = []

    /// Firestore-backed set of UIDs the current user has blocked. This is the
    /// authoritative source — `blockedUsers` is derived from it. Loaded on every
    /// sign-in so blocks persist across devices, fresh installs, and relaunches
    /// (Apple Guideline 1.2 requires blocks to survive app restart).
    @Published var blockedUserIDs: Set<String> = []

    /// IDs of posts the current user has reported.
    @Published var reportedPostIDs: Set<String> = []

    /// Set of usernames the current user follows.
    @Published var followingUsernames: Set<String> = []

    /// True while simulated "load more" network fetch is running.
    @Published var isLoadingMore: Bool = false

    /// True while the initial sign-in feed fetch is still in flight. HomeView
    /// shows a centered spinner (instead of the genuinely-empty zero-state)
    /// while this is true, then swaps straight to the posts the instant they
    /// arrive — no scroll required (Issue 2). Defaults to `true` so a fresh
    /// launch shows the spinner; ContentView sets it `false` once the sign-in
    /// feed load settles, and back to `true` on sign-out.
    @Published var isLoadingFeed: Bool = true

    private init() {}

    // MARK: - Feed (visible posts)

    /// Posts filtered to exclude blocked users and reported posts.
    ///
    /// Every visibility decision routes through `isBlocked(userId:username:)`
    /// so the feed, comment list, DM list, and user search all share ONE
    /// matching rule. A post is hidden only when its author's NON-EMPTY userId
    /// matches a blocked userId, or its NON-EMPTY username matches a blocked
    /// username. An empty identifier never matches — so posts whose
    /// `user_id`/`username` are absent in Firestore (decoded to "") are NOT
    /// swept up when a block exists. That empty-vs-empty match was the cause of
    /// the "block one user → entire feed vanishes" over-match.
    var visiblePosts: [LegoPost] {
        let afterBlock = posts.filter {
            !isBlocked(userId: $0.userId, username: $0.username)
        }
        logVisibleFilter(total: posts.count, kept: afterBlock.count)
        return afterBlock.filter { !reportedPostIDs.contains($0.id) }
    }

    /// Returns true ONLY when this content's author is genuinely blocked:
    /// a non-empty userId present in `blockedUserIDs`, or a non-empty username
    /// present in `blockedUsers`. Empty/nil identifiers are treated as
    /// "not blocked", so content with a missing author field is never hidden by
    /// a stray empty entry (defense-in-depth alongside the empty-filtering done
    /// when the blocked sets are populated). Used by the feed, comment filter,
    /// DM list, and user search so all four stay consistent.
    func isBlocked(userId: String, username: String) -> Bool {
        (!userId.isEmpty && blockedUserIDs.contains(userId)) ||
        (!username.isEmpty && blockedUsers.contains(username))
    }

    /// One-line over-match canary for the block filter. Logs only when at least
    /// one block is active AND the (blocked, hidden, total) signature changes,
    /// so SwiftUI re-renders don't spam the console but a regression — e.g.
    /// hiding all T posts after a single block — is immediately visible.
    private var lastVisibleFilterLog = ""
    private func logVisibleFilter(total: Int, kept: Int) {
        let blockedEntries = blockedUserIDs.count + blockedUsers.count
        guard blockedEntries > 0 else { return }
        let hidden = total - kept
        let signature = "\(blockedEntries)|\(hidden)|\(total)"
        guard signature != lastVisibleFilterLog else { return }
        lastVisibleFilterLog = signature
        print("[PostStore] visiblePosts — \(blockedEntries) blocked entries, hid \(hidden) of \(total) posts")
    }

    // MARK: - Post Actions

    /// Adds a new photo or video post to the top of the feed.
    func addPost(_ post: LegoPost, image: UIImage? = nil, videoURL: URL? = nil) {
        posts.insert(post, at: 0)
        if let image { postImages[post.id] = image }
        if let videoURL { postVideoURLs[post.id] = videoURL }
    }

    /// Toggles the like state and updates the count.
    func toggleLike(_ post: LegoPost) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        if likedPostIDs.contains(post.id) {
            likedPostIDs.remove(post.id)
            posts[index].likeCount -= 1
        } else {
            likedPostIDs.insert(post.id)
            posts[index].likeCount += 1
        }
    }

    func isLiked(_ post: LegoPost) -> Bool {
        likedPostIDs.contains(post.id)
    }

    // MARK: - Comments

    /// Returns comments for a post, sorted oldest-first, with comments by
    /// blocked users filtered out at read time so the block applies instantly.
    func comments(for postId: String) -> [Comment] {
        (comments[postId] ?? [])
            .filter { !isBlocked(userId: $0.userId, username: $0.username) }
            .sorted { $0.postedDate < $1.postedDate }
    }

    /// Adds a filtered comment to the post and increments the comment count.
    func addComment(to post: LegoPost, text: String, username: String = "") {
        let actualUsername = username.isEmpty ? (UserSession.shared.username) : username
        let filtered = BadWordFilter.filter(text)
        let comment = Comment(
            id: UUID().uuidString,
            postId: post.id,
            userId: UserSession.shared.uid,
            username: actualUsername,
            text: filtered,
            postedDate: Date()
        )
        if comments[post.id] == nil { comments[post.id] = [] }
        comments[post.id]?.append(comment)

        // Update comment count on the post
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index].commentCount += 1
        }
    }

    // MARK: - Blocking
    //
    // Two-tier model:
    //   • blockedUserIDs is the authoritative Firestore-backed set (uid → block)
    //   • blockedUsers mirrors the usernames so the existing username-keyed
    //     content filters still hide content immediately.
    //
    // All three mutating methods update in-memory state synchronously so the
    // feed/DM list/comment list re-renders without the blocked user's content
    // before the Firestore write completes (Apple Guideline 1.2: blocks must
    // take effect "instantly", no app restart).

    /// Blocks a user. Updates in-memory state immediately, then persists to
    /// Firestore so the block survives relaunch and applies on any device.
    func blockUser(userId: String, username: String, reason: String = "User blocked from in-app menu") {
        if !userId.isEmpty { blockedUserIDs.insert(userId) }
        if !username.isEmpty { blockedUsers.insert(username) }

        let currentUid      = UserSession.shared.uid
        let currentUsername = UserSession.shared.username
        guard !currentUid.isEmpty, !userId.isEmpty else { return }

        Task {
            do {
                try await FirebaseService.shared.blockUser(
                    currentUserId:   currentUid,
                    currentUsername: currentUsername,
                    targetUserId:    userId,
                    targetUsername:  username,
                    reason:          reason
                )
            } catch {
                print("[PostStore] blockUser Firestore write failed: \(error.localizedDescription)")
            }
        }
    }

    /// Legacy username-only block kept so existing call sites compile. Prefer
    /// `blockUser(userId:username:)` whenever a userId is available.
    func blockUser(_ username: String) {
        blockUser(userId: "", username: username)
    }

    func unblockUser(userId: String, username: String) {
        blockedUserIDs.remove(userId)
        blockedUsers.remove(username)
        let currentUid = UserSession.shared.uid
        guard !currentUid.isEmpty, !userId.isEmpty else { return }
        Task {
            try? await FirebaseService.shared.unblockUser(
                currentUserId: currentUid,
                targetUserId:  userId
            )
        }
    }

    func unblockUser(_ username: String) {
        blockedUsers.remove(username)
    }

    func isBlocked(_ username: String) -> Bool {
        !username.isEmpty && blockedUsers.contains(username)
    }

    /// Loads blocked users from Firestore into in-memory state. Called on
    /// every sign-in by ContentView so the filter applies before any feed,
    /// DM list, or comment list renders.
    func loadBlockedUsers(currentUserId: String) async {
        guard !currentUserId.isEmpty else { return }
        do {
            let blocks = try await FirebaseService.shared.fetchBlockedUsers(userId: currentUserId)
            blockedUserIDs = Set(blocks.map { $0.id }.filter { !$0.isEmpty })
            blockedUsers   = Set(blocks.map { $0.username }.filter { !$0.isEmpty })
            print("[PostStore] loadBlockedUsers — applied \(blockedUserIDs.count) UID blocks, \(blockedUsers.count) username blocks")
        } catch {
            print("[PostStore] loadBlockedUsers failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Reporting

    func reportPost(_ post: LegoPost) {
        reportedPostIDs.insert(post.id)
    }

    // MARK: - Following

    func isFollowing(_ username: String) -> Bool {
        followingUsernames.contains(username)
    }

    func toggleFollow(_ username: String) {
        if followingUsernames.contains(username) {
            followingUsernames.remove(username)
        } else {
            followingUsernames.insert(username)
        }
    }

    /// THE single entry point for follow / unfollow actions, used by EVERY
    /// Follow button (Home, Search, OtherProfile, SetDetail). It keeps all four
    /// follow-tracking mechanisms in sync so they can never drift apart again:
    ///   1. Firestore counters + subcollections — via `FirebaseService.followUser`
    ///      / `unfollowUser` (the authoritative, batch-written source of truth).
    ///   2. `FollowingRegistry` (UID set) — drives `FollowingBadge`.
    ///   3. `followingUsernames` (username set) — drives every Follow-button
    ///      label, the Home "Following" feed filter, and the Leaderboard.
    ///   4. the signed-in user's in-memory `following_count` — so their own
    ///      profile updates live.
    ///
    /// The in-memory state (2 + 3 + 4) is updated optimistically for an instant
    /// UI response, then rolled back if the Firestore write fails.
    func performFollow(targetUid: String, username: String, shouldFollow: Bool) async {
        let currentUid = UserSession.shared.uid
        guard !currentUid.isEmpty, !targetUid.isEmpty, targetUid != currentUid else { return }

        // Optimistic in-memory update (mechanisms 2 + 3).
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if shouldFollow {
                followingUsernames.insert(username)
                FollowingRegistry.shared.follow(uid: targetUid)
            } else {
                followingUsernames.remove(username)
                FollowingRegistry.shared.unfollow(uid: targetUid)
            }
        }

        do {
            if shouldFollow {
                try await FirebaseService.shared.followUser(currentUserId: currentUid, targetUserId: targetUid)
            } else {
                try await FirebaseService.shared.unfollowUser(currentUserId: currentUid, targetUserId: targetUid)
            }
            // Mechanism 4: keep the signed-in user's own following count live
            // without a full re-fetch (mirrors the Firestore increment).
            UserSession.shared.adjustFollowingCount(by: shouldFollow ? 1 : -1)
        } catch {
            // Roll back the optimistic update so the UI matches Firestore.
            withAnimation {
                if shouldFollow {
                    followingUsernames.remove(username)
                    FollowingRegistry.shared.unfollow(uid: targetUid)
                } else {
                    followingUsernames.insert(username)
                    FollowingRegistry.shared.follow(uid: targetUid)
                }
            }
            print("[PostStore] performFollow error: \(error)")
        }
    }

    // MARK: - Comment Utilities

    /// Replaces comments for a specific post (called after Firestore fetch).
    ///
    /// Bug-17 follow-up: previously this unconditionally wrote
    /// `posts[index].commentCount = comments.count`, which destructively
    /// zeroed the denormalized count whenever a fetch returned an empty array
    /// (race against the seeder, transient permission failure, etc.). The
    /// zeroed count then persisted across the feed and survived navigating
    /// back. We now only update the stored count when the fetch actually
    /// returned comments — an empty result is treated as a no-op, leaving the
    /// authoritative `comment_count` on the post intact.
    func setComments(_ comments: [Comment], for postId: String) {
        self.comments[postId] = comments
        guard !comments.isEmpty,
              let index = posts.firstIndex(where: { $0.id == postId }) else { return }
        posts[index].commentCount = comments.count
    }

    // MARK: - Infinite Scroll

    /// Placeholder for future server-side pagination. Currently a no-op.
    func loadMorePosts() {
        // Will be implemented with real Firestore pagination in a future sprint
    }

    // MARK: - Pull to Refresh

    /// Reloads all posts from Firestore, newest first.
    func refreshPosts() async {
        do {
            let fresh = try await FirebaseService.shared.fetchFeedPosts(limit: 30)
            // Also reload liked IDs
            let uid = UserSession.shared.uid
            var liked = likedPostIDs
            if !uid.isEmpty {
                let ids = fresh.map { $0.id }
                liked = (try? await FirebaseService.shared.fetchLikedPostIds(userId: uid, postIds: ids)) ?? liked
            }
            posts = fresh
            likedPostIDs = liked
        } catch {
            print("[PostStore] refreshPosts error: \(error)")
        }
    }
}
