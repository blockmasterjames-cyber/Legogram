import SwiftUI
import Foundation

/// PostStore is the single source of truth for posts, comments, likes, blocks, and reports.
/// Sprint 3 adds: comments, video support, user blocking, post reporting, and infinite scroll simulation.
@MainActor
final class PostStore: ObservableObject {

    // MARK: - Singleton
    static let shared = PostStore()

    // MARK: - Published State

    /// All posts in the feed, newest first.
    @Published var posts: [LegoPost] = PostStore.seedPosts

    /// Photos for posts keyed by post ID (in-memory; Firebase Storage in Sprint 4).
    @Published var postImages: [String: UIImage] = [:]

    /// Local video file URLs for video posts keyed by post ID.
    @Published var postVideoURLs: [String: URL] = [:]

    /// IDs of posts the current user has liked.
    @Published var likedPostIDs: Set<String> = []

    /// Comments keyed by post ID.
    @Published var comments: [String: [Comment]] = PostStore.seedComments

    /// Usernames the current user has blocked (their posts are hidden from the feed).
    @Published var blockedUsers: Set<String> = []

    /// IDs of posts the current user has reported.
    @Published var reportedPostIDs: Set<String> = []

    /// Set of usernames the current user follows.
    @Published var followingUsernames: Set<String> = ["brickmaster99"]

    /// True while simulated "load more" network fetch is running.
    @Published var isLoadingMore: Bool = false

    private var nextBatchIndex = 0
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
    func addComment(to post: LegoPost, text: String, username: String = "blockmasterjames") {
        let filtered = BadWordFilter.filter(text)
        let comment = Comment(
            id: UUID().uuidString,
            postId: post.id,
            userId: "current-user",
            username: username,
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

    // MARK: - Infinite Scroll

    private let extraBatches: [[LegoPost]] = [
        // Batch 1 — loads after first scroll to bottom
        [
            LegoPost(id: "batch1-1", userId: "u3", username: "technicjane",
                     imageURL: "", legoSetNumber: "42115",
                     legoSetName: "Lamborghini Sián FKP 37",
                     description: "The suspension on this is amazing!", likeCount: 89,
                     commentCount: 12, buyLink: "https://www.lego.com/en-us/product/lamborghini-sian-fkp-37-42115",
                     affiliateLink: "", estimatedEarnings: 0.32, postedDate: Date().addingTimeInterval(-28800), tags: ["technic"]),
            LegoPost(id: "batch1-2", userId: "u4", username: "hogwartsbuilder",
                     imageURL: "", legoSetNumber: "71043",
                     legoSetName: "Hogwarts Castle",
                     description: "Finally finished! This one took all summer 🧙‍♂️", likeCount: 521,
                     commentCount: 76, buyLink: "https://www.lego.com/en-us/product/hogwarts-castle-71043",
                     affiliateLink: "", estimatedEarnings: 2.10, postedDate: Date().addingTimeInterval(-14400), tags: ["harrypotter"]),
        ],
        // Batch 2
        [
            LegoPost(id: "batch2-1", userId: "u5", username: "speedkid42",
                     imageURL: "", legoSetNumber: "76916",
                     legoSetName: "Porsche 963",
                     description: "Zoom zoom! My favorite Speed Champions set", likeCount: 44,
                     commentCount: 5, buyLink: "https://www.lego.com/en-us/product/porsche-963-76916",
                     affiliateLink: "", estimatedEarnings: 0.10, postedDate: Date().addingTimeInterval(-50000), tags: ["speedchampions"]),
            LegoPost(id: "batch2-2", userId: "u6", username: "architectbob",
                     imageURL: "", legoSetNumber: "21058",
                     legoSetName: "Great Pyramid of Giza",
                     description: "Building the wonders of the world one brick at a time 🏛️", likeCount: 198,
                     commentCount: 23, buyLink: "https://www.lego.com/en-us/product/great-pyramid-of-giza-21058",
                     affiliateLink: "", estimatedEarnings: 0.80, postedDate: Date().addingTimeInterval(-72000), tags: ["architecture"]),
        ],
    ]

    /// Simulates loading more posts from a server. Called when the user scrolls to the bottom.
    func loadMorePosts() {
        guard !isLoadingMore, nextBatchIndex < extraBatches.count else { return }
        isLoadingMore = true
        let batch = extraBatches[nextBatchIndex]
        nextBatchIndex += 1

        // Simulate 1.2 second network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self else { return }
            self.posts.append(contentsOf: batch)
            self.isLoadingMore = false
        }
    }

    // MARK: - Seed Data (10 starter posts)

    static let seedPosts: [LegoPost] = [
        LegoPost(id: "preview-post-001", userId: "preview-user-001", username: "brickmaster99",
                 imageURL: "", legoSetNumber: "75192", legoSetName: "Millennium Falcon",
                 description: "Took me 3 weeks but it was worth every brick! 🚀",
                 likeCount: 342, commentCount: 3,
                 buyLink: "https://www.lego.com/en-us/product/millennium-falcon-75192",
                 affiliateLink: "", estimatedEarnings: 1.84,
                 postedDate: Date().addingTimeInterval(-7200), tags: ["starwars", "ucs"]),

        LegoPost(id: "preview-post-002", userId: "preview-user-002", username: "legolover_emma",
                 imageURL: "", legoSetNumber: "10300", legoSetName: "Back to the Future Time Machine",
                 description: "Classic! Every LEGO fan needs this one. 🚗⚡️",
                 likeCount: 218, commentCount: 2,
                 buyLink: "https://www.lego.com/en-us/product/back-to-the-future-time-machine-10300",
                 affiliateLink: "", estimatedEarnings: 0.94,
                 postedDate: Date().addingTimeInterval(-3600), tags: ["icons", "backtothefuture"]),

        LegoPost(id: "preview-post-003", userId: "u7", username: "marvelfan_zoe",
                 imageURL: "", legoSetNumber: "76210", legoSetName: "Hulkbuster",
                 description: "This thing is MASSIVE. My desk is officially a superhero HQ 💪",
                 likeCount: 411, commentCount: 2,
                 buyLink: "https://www.lego.com/en-us/product/hulkbuster-76210",
                 affiliateLink: "", estimatedEarnings: 1.65,
                 postedDate: Date().addingTimeInterval(-10800), tags: ["marvel", "hulkbuster"]),

        LegoPost(id: "preview-post-004", userId: "u8", username: "citybuilder_max",
                 imageURL: "", legoSetNumber: "60380", legoSetName: "Downtown",
                 description: "My LEGO city just got its best building yet! 🏙️",
                 likeCount: 167, commentCount: 2,
                 buyLink: "https://www.lego.com/en-us/product/downtown-60380",
                 affiliateLink: "", estimatedEarnings: 0.67,
                 postedDate: Date().addingTimeInterval(-21600), tags: ["city"]),

        LegoPost(id: "preview-post-005", userId: "u9", username: "ideasfan_lily",
                 imageURL: "", legoSetNumber: "21333", legoSetName: "Vincent van Gogh - The Starry Night",
                 description: "Art + LEGO = perfect combo 🎨 This masterpiece took 5 evenings!",
                 likeCount: 893, commentCount: 2,
                 buyLink: "https://www.lego.com/en-us/product/vincent-van-gogh-the-starry-night-21333",
                 affiliateLink: "", estimatedEarnings: 3.57,
                 postedDate: Date().addingTimeInterval(-43200), tags: ["ideas", "art"]),
    ]

    static let seedComments: [String: [Comment]] = [
        "preview-post-001": [
            Comment(id: "c1", postId: "preview-post-001", userId: "u2",
                    username: "legolover_emma",
                    text: "That looks incredible! How long did the cockpit take?",
                    postedDate: Date().addingTimeInterval(-6000)),
            Comment(id: "c2", postId: "preview-post-001", userId: "u3",
                    username: "technicjane",
                    text: "Best Star Wars set ever made 🚀",
                    postedDate: Date().addingTimeInterval(-5000)),
            Comment(id: "c3", postId: "preview-post-001", userId: "u4",
                    username: "citybuilder_max",
                    text: "I need this on my shelf! Saving up now",
                    postedDate: Date().addingTimeInterval(-4000)),
        ],
        "preview-post-002": [
            Comment(id: "c4", postId: "preview-post-002", userId: "u5",
                    username: "marvelfan_zoe",
                    text: "Great Scott! This set is amazing 😂",
                    postedDate: Date().addingTimeInterval(-3000)),
            Comment(id: "c5", postId: "preview-post-002", userId: "u1",
                    username: "brickmaster99",
                    text: "The flux capacitor piece is so cool!",
                    postedDate: Date().addingTimeInterval(-2000)),
        ],
        "preview-post-003": [
            Comment(id: "c6", postId: "preview-post-003", userId: "u8",
                    username: "brickmaster99",
                    text: "Iron Man fans unite! 🦾",
                    postedDate: Date().addingTimeInterval(-9000)),
            Comment(id: "c7", postId: "preview-post-003", userId: "u9",
                    username: "ideasfan_lily",
                    text: "Love the detail on the armor panels!",
                    postedDate: Date().addingTimeInterval(-8000)),
        ],
        "preview-post-004": [
            Comment(id: "c8", postId: "preview-post-004", userId: "u1",
                    username: "legolover_emma",
                    text: "Perfect addition to any LEGO city!",
                    postedDate: Date().addingTimeInterval(-20000)),
            Comment(id: "c9", postId: "preview-post-004", userId: "u2",
                    username: "brickmaster99",
                    text: "I love all the little minifigures in this set",
                    postedDate: Date().addingTimeInterval(-19000)),
        ],
        "preview-post-005": [
            Comment(id: "c10", postId: "preview-post-005", userId: "u3",
                    username: "hogwartsbuilder",
                    text: "This is my favorite Ideas set ever! 🎨",
                    postedDate: Date().addingTimeInterval(-40000)),
            Comment(id: "c11", postId: "preview-post-005", userId: "u4",
                    username: "speedkid42",
                    text: "The swirly colors look EXACTLY like the painting!",
                    postedDate: Date().addingTimeInterval(-38000)),
        ],
    ]
}
