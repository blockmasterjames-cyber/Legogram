import Foundation

/// Represents a BrickFeed user — a real person who logs in and posts LEGO builds.
/// Every field maps directly to a document in the Firestore "users" collection.
struct User: Identifiable, Codable, Hashable {

    // MARK: - Identity
    var id: String
    var username: String
    var displayName: String
    var bio: String
    var avatarURL: String
    var backgroundURL: String

    // MARK: - Social Counts
    var followerCount: Int
    var followingCount: Int
    var postCount: Int
    var totalLikes: Int

    // MARK: - Points System (replaces earnings)
    /// Total points earned through posting, receiving likes, comments, and follows.
    /// Posting = 10 pts, Like received = 2 pts, Comment received = 5 pts, Follow received = 1 pt
    var totalPoints: Int

    // MARK: - Kid Safety
    var isKidAccount: Bool
    var parentEmail: String

    // MARK: - Metadata
    var joinDate: Date
    var birthday: Date?

    // MARK: - Firestore Field Keys
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName    = "display_name"
        case bio
        case avatarURL      = "avatar_url"
        case backgroundURL  = "background_url"
        case followerCount  = "follower_count"
        case followingCount = "following_count"
        case postCount      = "post_count"
        case totalLikes     = "total_likes"
        case totalPoints    = "total_points"
        case isKidAccount   = "is_kid_account"
        case parentEmail    = "parent_email"
        case joinDate       = "join_date"
        case birthday
    }
}

// MARK: - Placeholder / Preview
extension User {
    static let placeholder = User(
        id: "preview-user-001",
        username: "brickmaster99",
        displayName: "James the Builder",
        bio: "Building one brick at a time 🧱",
        avatarURL: "",
        backgroundURL: "",
        followerCount: 0,
        followingCount: 0,
        postCount: 0,
        totalLikes: 0,
        totalPoints: 0,
        isKidAccount: false,
        parentEmail: "",
        joinDate: Date(),
        birthday: nil
    )
}
