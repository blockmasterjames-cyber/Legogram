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

    /// Usernames the current user has blocked (their posts are hidden from the feed).
    @Published var blockedUsers: Set<String> = []

    /// IDs of posts the current user has reported.
    @Published var reportedPostIDs: Set<String> = []

    /// Set of usernames the current user follows.
    @Published var followingUsernames: Set<String> = []

    /// True while simulated "load more" network fetch is running.
    @Published var isLoadingMore: Bool = false

    private init() {}

    // MARK: - Feed (visible posts)

    /// Posts filtered to exclude blocked users and reported posts.
    var visiblePosts: [LegoPost] {
        posts.filter {
            !blockedUsers.contains($0.username) &&
            !reportedPostIDs.contains($0.id)
        }
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

    /// Returns comments for a post, sorted oldest-first.
    func comments(for postId: String) -> [Comment] {
        (comments[postId] ?? []).sorted { $0.postedDate < $1.postedDate }
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

    func blockUser(_ username: String) {
        blockedUsers.insert(username)
    }

    func unblockUser(_ username: String) {
        blockedUsers.remove(username)
    }

    func isBlocked(_ username: String) -> Bool {
        blockedUsers.contains(username)
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
}
