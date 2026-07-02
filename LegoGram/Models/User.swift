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
    /// Posting = 10 pts, Like received = 2 pts, Comment received = 5 pts, Follow received = 1 pt.
    /// One-time bonuses: first avatar/bio/banner = 5 pts each, first-ever follow of a user = 2 pts.
    var totalPoints: Int

    // MARK: - Kid Safety
    var isKidAccount: Bool
    var isUnder9: Bool
    var parentEmail: String

    // MARK: - Privacy
    /// Whether other users can start a DM conversation with this user
    /// (Firestore `accepts_dms`). Defaults to `true` so existing accounts and
    /// documents that predate this field still receive DMs.
    var acceptsDMs: Bool = true

    // MARK: - Metadata
    var joinDate: Date
    var birthday: Date?

    // MARK: - Moderation
    /// Admin-set ban flag (Firestore `is_banned`). Read-only from the app's
    /// perspective: it is written ONLY by the admin ban/unban methods, never by
    /// `saveUser`, and the rules restrict it to admins. Declared last (with a
    /// default) so the memberwise initializer's other call sites are unaffected.
    var isBanned: Bool = false

    // MARK: - One-Time Profile Awards
    /// Persistent "already awarded" flags for the once-ever profile-completion
    /// bonuses (Firestore `awarded_avatar` / `awarded_bio` / `awarded_banner`).
    /// They only ever go false → true and are written EXCLUSIVELY by
    /// `FirebaseService.grantProfileCompletionBonus` (never by `saveUser`, so a
    /// stale in-memory copy can't reset one and re-open an award). Missing on
    /// old documents = not yet awarded. Declared last with defaults, same as
    /// `isBanned`, so existing memberwise-init call sites are unaffected.
    var awardedAvatar: Bool = false
    var awardedBio: Bool = false
    var awardedBanner: Bool = false

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
        case isUnder9       = "is_under_9"
        case isBanned       = "is_banned"
        case parentEmail    = "parent_email"
        case acceptsDMs     = "accepts_dms"
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
        isUnder9: false,
        parentEmail: "",
        joinDate: Date(),
        birthday: nil
    )
}
