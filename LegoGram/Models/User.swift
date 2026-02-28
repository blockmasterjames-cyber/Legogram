import Foundation

/// Represents a LegoGram user — a real person who logs in and posts LEGO builds.
/// Every field maps directly to a document in the Firestore "users" collection.
struct User: Identifiable, Codable, Hashable {

    // MARK: - Identity
    /// Unique ID assigned by Firebase Auth (never changes).
    var id: String

    /// The short @handle the user picks, like "brickmaster99". Must be unique.
    var username: String

    /// The full display name shown on the profile, like "James the Builder".
    var displayName: String

    /// A short sentence about themselves shown on the profile.
    var bio: String

    /// URL of the user's profile picture stored in Firebase Storage.
    var avatarURL: String

    // MARK: - Social Counts
    /// How many people follow this user.
    var followerCount: Int

    /// How many people this user follows.
    var followingCount: Int

    /// Total number of posts this user has shared.
    var postCount: Int

    /// Combined likes across all of this user's posts.
    var totalLikes: Int

    // MARK: - Earnings
    /// Total money earned through affiliate links on their posts (in USD).
    var totalEarnings: Double

    // MARK: - Kid Safety
    /// True if the account is registered as a kid account (under 13).
    var isKidAccount: Bool

    /// Parent's email address — required for kid accounts.
    var parentEmail: String

    // MARK: - Metadata
    /// The date and time the account was created.
    var joinDate: Date

    // MARK: - Firestore Field Keys
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName    = "display_name"
        case bio
        case avatarURL      = "avatar_url"
        case followerCount  = "follower_count"
        case followingCount = "following_count"
        case postCount      = "post_count"
        case totalLikes     = "total_likes"
        case totalEarnings  = "total_earnings"
        case isKidAccount   = "is_kid_account"
        case parentEmail    = "parent_email"
        case joinDate       = "join_date"
    }
}

// MARK: - Placeholder / Preview
extension User {
    /// A fake user used in SwiftUI previews and placeholder screens.
    static let placeholder = User(
        id: "preview-user-001",
        username: "brickmaster99",
        displayName: "James the Builder",
        bio: "Building one brick at a time 🧱",
        avatarURL: "",
        followerCount: 1_200,
        followingCount: 348,
        postCount: 24,
        totalLikes: 8_500,
        totalEarnings: 12.40,
        isKidAccount: false,
        parentEmail: "",
        joinDate: Date()
    )
}
