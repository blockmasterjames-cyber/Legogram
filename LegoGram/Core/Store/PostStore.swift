import SwiftUI
import Foundation

/// PostStore holds all the LEGO build posts the app knows about.
/// It is the single source of truth for the Home feed, the Profile grid, and new post submission.
///
/// Right now posts live only in memory (they reset when you close the app).
/// In Sprint 3 we will sync everything with Firebase Firestore + Storage.
@MainActor
final class PostStore: ObservableObject {

    // MARK: - Singleton
    static let shared = PostStore()

    // MARK: - Published State

    /// All posts in the feed, newest first.
    @Published var posts: [LegoPost] = [
        LegoPost(
            id: "preview-post-001",
            userId: "preview-user-001",
            username: "brickmaster99",
            imageURL: "",
            legoSetNumber: "75192",
            legoSetName: "Millennium Falcon",
            description: "Took me 3 weeks but it was worth every brick! 🚀",
            likeCount: 342,
            commentCount: 47,
            buyLink: "https://www.lego.com/en-us/product/millennium-falcon-75192",
            affiliateLink: "",
            estimatedEarnings: 1.84,
            postedDate: Date().addingTimeInterval(-7200),
            tags: ["starwars", "ucs", "millennium falcon"]
        ),
        LegoPost(
            id: "preview-post-002",
            userId: "preview-user-002",
            username: "legolover_emma",
            imageURL: "",
            legoSetNumber: "10300",
            legoSetName: "Back to the Future Time Machine",
            description: "Classic! Every LEGO fan needs this one. 🚗⚡️",
            likeCount: 218,
            commentCount: 31,
            buyLink: "https://www.lego.com/en-us/product/back-to-the-future-time-machine-10300",
            affiliateLink: "",
            estimatedEarnings: 0.94,
            postedDate: Date().addingTimeInterval(-3600),
            tags: ["icons", "backtothefuture"]
        )
    ]

    /// Photos for posts keyed by post ID.
    /// Stored in memory because Firebase Storage comes in Sprint 3.
    @Published var postImages: [String: UIImage] = [:]

    /// IDs of posts the current user has liked, so the heart stays red after tapping.
    @Published var likedPostIDs: Set<String> = []

    private init() {}

    // MARK: - Actions

    /// Adds a new post to the top of the feed.
    /// - Parameters:
    ///   - post: The new `LegoPost` to publish.
    ///   - image: The photo the user picked from the camera or library.
    func addPost(_ post: LegoPost, image: UIImage?) {
        posts.insert(post, at: 0)
        if let image {
            postImages[post.id] = image
        }
    }

    /// Toggles the like state for a post and updates the like count.
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

    /// Returns true if the current user has liked the given post.
    func isLiked(_ post: LegoPost) -> Bool {
        likedPostIDs.contains(post.id)
    }
}
