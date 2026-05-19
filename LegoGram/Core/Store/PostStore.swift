import SwiftUI
import Foundation

/// PostStore is the single source of truth for posts, comments, likes, blocks, and reports.
/// Sprint 9: All fake/seed data removed. OG posts loaded via OGAccountsService.
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

    private init() {}

    // MARK: - Feed (visible posts)

    /// Posts filtered to exclude blocked users and reported posts.
    /// Filters by BOTH userId and username so a blocked user stays hidden
    /// even if their username record is missing on a particular document.
    var visiblePosts: [LegoPost] {
        posts.filter {
            !blockedUserIDs.contains($0.userId) &&
            !blockedUsers.contains($0.username) &&
            !reportedPostIDs.contains($0.id)
        }
    }

    /// Returns true if a comment, message, or other piece of content from
    /// `userId` / `username` is currently blocked by the signed-in user.
    func isBlocked(userId: String, username: String) -> Bool {
        blockedUserIDs.contains(userId) || blockedUsers.contains(username)
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
        blockedUsers.contains(username)
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

    // MARK: - Comment Utilities

    /// Replaces comments for a specific post (called after Firestore fetch).
    func setComments(_ comments: [Comment], for postId: String) {
        self.comments[postId] = comments
        // Sync comment count
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].commentCount = comments.count
        }
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
