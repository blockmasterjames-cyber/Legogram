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
        let birthdayTimestamp = data["birthday"] as? Timestamp

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
            joinDate:       joinTimestamp?.dateValue() ?? Date(),
            birthday:       birthdayTimestamp?.dateValue()
        )
    }

    /// Writes (or overwrites) a user document in Firestore.
    func saveUser(_ user: User) async throws {
        var data: [String: Any] = [
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
        if let birthday = user.birthday {
            data["birthday"] = Timestamp(date: birthday)
        }
        try await db.collection("users").document(user.id).setData(data, merge: true)
    }

    // =========================================================================
    // MARK: - User Search
    // =========================================================================

    /// Searches for users whose username or display_name contains the query (case-insensitive prefix match).
    /// Firestore doesn't support native case-insensitive search, so we store a lowercase range query.
    func searchUsers(query: String, limit: Int = 20) async throws -> [User] {
        let lowered = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !lowered.isEmpty else { return [] }

        // Firestore range trick: search where field >= query and < query + high unicode char
        let end = lowered + "\u{f8ff}"

        // Search by username
        let usernameSnap = try await db.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: lowered)
            .whereField("username", isLessThan: end)
            .limit(to: limit)
            .getDocuments()

        // Search by display_name
        let displaySnap = try await db.collection("users")
            .whereField("display_name", isGreaterThanOrEqualTo: lowered)
            .whereField("display_name", isLessThan: end)
            .limit(to: limit)
            .getDocuments()

        // Merge results, deduplicating by document ID
        var seen = Set<String>()
        var results: [User] = []

        for doc in usernameSnap.documents + displaySnap.documents {
            let uid = doc.documentID
            guard !seen.contains(uid) else { continue }
            seen.insert(uid)

            let data = doc.data()
            let joinTimestamp = data["join_date"] as? Timestamp
            let birthdayTimestamp = data["birthday"] as? Timestamp
            let user = User(
                id:             uid,
                username:       data["username"]        as? String ?? "",
                displayName:    data["display_name"]    as? String ?? "",
                bio:            data["bio"]             as? String ?? "",
                avatarURL:      data["avatar_url"]      as? String ?? "",
                followerCount:  data["follower_count"]  as? Int    ?? 0,
                followingCount: data["following_count"]  as? Int   ?? 0,
                postCount:      data["post_count"]      as? Int    ?? 0,
                totalLikes:     data["total_likes"]     as? Int    ?? 0,
                totalEarnings:  data["total_earnings"]  as? Double ?? 0,
                isKidAccount:   data["is_kid_account"]  as? Bool   ?? false,
                parentEmail:    data["parent_email"]    as? String ?? "",
                joinDate:       joinTimestamp?.dateValue() ?? Date(),
                birthday:       birthdayTimestamp?.dateValue()
            )
            results.append(user)
        }

        return results
    }

    // =========================================================================
    // MARK: - Following Operations
    // =========================================================================

    /// Adds a follow relationship: currentUser follows targetUserId.
    func followUser(currentUserId: String, targetUserId: String) async throws {
        let batch = db.batch()

        // Add to current user's "following" subcollection
        let followingRef = db.collection("users").document(currentUserId)
            .collection("following").document(targetUserId)
        batch.setData(["followed_at": Timestamp(date: Date())], forDocument: followingRef)

        // Add to target user's "followers" subcollection
        let followerRef = db.collection("users").document(targetUserId)
            .collection("followers").document(currentUserId)
        batch.setData(["followed_at": Timestamp(date: Date())], forDocument: followerRef)

        // Increment counts
        let currentUserRef = db.collection("users").document(currentUserId)
        batch.updateData(["following_count": FieldValue.increment(Int64(1))], forDocument: currentUserRef)

        let targetUserRef = db.collection("users").document(targetUserId)
        batch.updateData(["follower_count": FieldValue.increment(Int64(1))], forDocument: targetUserRef)

        try await batch.commit()
    }

    /// Removes a follow relationship: currentUser unfollows targetUserId.
    func unfollowUser(currentUserId: String, targetUserId: String) async throws {
        let batch = db.batch()

        let followingRef = db.collection("users").document(currentUserId)
            .collection("following").document(targetUserId)
        batch.deleteDocument(followingRef)

        let followerRef = db.collection("users").document(targetUserId)
            .collection("followers").document(currentUserId)
        batch.deleteDocument(followerRef)

        let currentUserRef = db.collection("users").document(currentUserId)
        batch.updateData(["following_count": FieldValue.increment(Int64(-1))], forDocument: currentUserRef)

        let targetUserRef = db.collection("users").document(targetUserId)
        batch.updateData(["follower_count": FieldValue.increment(Int64(-1))], forDocument: targetUserRef)

        try await batch.commit()
    }

    /// Checks if currentUser follows targetUserId.
    func isFollowing(currentUserId: String, targetUserId: String) async throws -> Bool {
        let doc = try await db.collection("users").document(currentUserId)
            .collection("following").document(targetUserId).getDocument()
        return doc.exists
    }

    /// Fetches all user IDs that currentUser follows.
    func fetchFollowingIds(userId: String) async throws -> Set<String> {
        let snap = try await db.collection("users").document(userId)
            .collection("following").getDocuments()
        return Set(snap.documents.map { $0.documentID })
    }

    /// Fetches the follower count for a user.
    func fetchFollowerCount(userId: String) async throws -> Int {
        let snap = try await db.collection("users").document(userId)
            .collection("followers").getDocuments()
        return snap.documents.count
    }

    /// Fetches the following count for a user.
    func fetchFollowingCount(userId: String) async throws -> Int {
        let snap = try await db.collection("users").document(userId)
            .collection("following").getDocuments()
        return snap.documents.count
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
