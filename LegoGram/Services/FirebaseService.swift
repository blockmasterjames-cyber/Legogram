import Foundation
import FirebaseFirestore
import FirebaseStorage

/// FirebaseService handles all reading and writing to the cloud database (Firestore)
/// and cloud file storage (Firebase Storage).
final class FirebaseService: ObservableObject {

    // MARK: - Singleton
    static let shared = FirebaseService()

    private let db = Firestore.firestore()

    private init() {}

    // =========================================================================
    // MARK: - User Operations
    // =========================================================================

    /// Fetches a user document from the Firestore "users" collection.
    func fetchUser(userId: String) async throws -> User {
        let doc = try await db.collection("users").document(userId).getDocument()

        guard doc.exists, let data = doc.data() else {
            throw FirebaseServiceError.documentNotFound
        }

        let joinTimestamp = data["join_date"] as? Timestamp

        return User(
            id:             userId,
            username:       data["username"]       as? String ?? "",
            displayName:    data["display_name"]   as? String ?? "",
            bio:            data["bio"]            as? String ?? "",
            avatarURL:      data["avatar_url"]     as? String ?? "",
            followerCount:  data["follower_count"] as? Int    ?? 0,
            followingCount: data["following_count"] as? Int   ?? 0,
            postCount:      data["post_count"]     as? Int    ?? 0,
            totalLikes:     data["total_likes"]    as? Int    ?? 0,
            totalEarnings:  data["total_earnings"] as? Double ?? 0,
            isKidAccount:   data["is_kid_account"] as? Bool   ?? false,
            parentEmail:    data["parent_email"]   as? String ?? "",
            joinDate:       joinTimestamp?.dateValue() ?? Date()
        )
    }

    /// Writes (or overwrites) a user document in Firestore.
    func saveUser(_ user: User) async throws {
        let data: [String: Any] = [
            "username":       user.username,
            "display_name":   user.displayName,
            "bio":            user.bio,
            "avatar_url":     user.avatarURL,
            "follower_count":  user.followerCount,
            "following_count": user.followingCount,
            "post_count":      user.postCount,
            "total_likes":     user.totalLikes,
            "total_earnings":  user.totalEarnings,
            "is_kid_account":  user.isKidAccount,
            "parent_email":    user.parentEmail,
            "join_date":       Timestamp(date: user.joinDate)
        ]
        try await db.collection("users").document(user.id).setData(data, merge: true)
    }

    // =========================================================================
    // MARK: - Post Operations
    // =========================================================================

    func fetchFeedPosts(limit: Int = 20) async throws -> [LegoPost] {
        return []
    }

    func publishPost(_ post: LegoPost) async throws {
        print("[FirebaseService] publishPost: \(post.id)")
    }

    // =========================================================================
    // MARK: - LEGO Set Operations
    // =========================================================================

    func fetchLegoSet(setNumber: String) async throws -> LegoSet? {
        return nil
    }

    // =========================================================================
    // MARK: - Storage Operations
    // =========================================================================

    func uploadImage(imageData: Data, path: String) async throws -> String {
        let storageRef = Storage.storage().reference().child(path)
        let _ = try await storageRef.putDataAsync(imageData)
        let url = try await storageRef.downloadURL()
        return url.absoluteString
    }
}

// MARK: - Errors

enum FirebaseServiceError: LocalizedError {
    case documentNotFound
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .documentNotFound: return "The requested document was not found."
        case .encodingFailed:   return "Failed to encode the data model."
        }
    }
}
