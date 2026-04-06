import Foundation

/// Represents a single comment on a LEGO build post.
/// Comments are filtered through BadWordFilter before being stored.
struct Comment: Identifiable, Codable, Hashable {

    // MARK: - Identity
    var id: String

    /// The post this comment belongs to.
    var postId: String

    /// Firebase Auth UID of the commenter.
    var userId: String

    /// Username of the commenter — stored here to avoid extra lookups.
    var username: String

    // MARK: - Content
    /// The comment text, already filtered for bad words. Max 200 characters.
    var text: String

    // MARK: - Profile Photo
    /// Avatar URL of the commenter. Empty string if not set.
    var avatarURL: String

    // MARK: - Metadata
    var postedDate: Date

    // MARK: - Firestore Field Keys
    enum CodingKeys: String, CodingKey {
        case id
        case postId     = "post_id"
        case userId     = "user_id"
        case username
        case text
        case avatarURL  = "avatar_url"
        case postedDate = "posted_date"
    }

    // MARK: - Convenience Init
    init(id: String, postId: String, userId: String, username: String,
         text: String, avatarURL: String = "", postedDate: Date) {
        self.id         = id
        self.postId     = postId
        self.userId     = userId
        self.username   = username
        self.text       = text
        self.avatarURL  = avatarURL
        self.postedDate = postedDate
    }
}

// MARK: - Helpers

extension Comment {
    /// A human-readable "time ago" string like "2m ago" or "1h ago".
    var timeAgo: String {
        let seconds = Int(Date().timeIntervalSince(postedDate))
        switch seconds {
        case 0..<60:   return "\(seconds)s ago"
        case 60..<3600: return "\(seconds / 60)m ago"
        case 3600..<86400: return "\(seconds / 3600)h ago"
        default: return "\(seconds / 86400)d ago"
        }
    }
}
