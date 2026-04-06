import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

/// FirebaseService handles all reading and writing to Firestore and Firebase Storage.
final class FirebaseService: ObservableObject {

    // MARK: - Singleton
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    private init() {}

    // =========================================================================
    // MARK: - User Operations
    // =========================================================================

    func fetchUser(userId: String) async throws -> User {
        let doc = try await db.collection("users").document(userId).getDocument()
        guard doc.exists, let data = doc.data() else {
            throw FirebaseServiceError.documentNotFound
        }
        return userFromData(data, id: userId)
    }

    func saveUser(_ user: User) async throws {
        var data: [String: Any] = [
            "username":        user.username,
            "display_name":    user.displayName,
            "bio":             user.bio,
            "avatar_url":      user.avatarURL,
            "background_url":  user.backgroundURL,
            "follower_count":  user.followerCount,
            "following_count": user.followingCount,
            "post_count":      user.postCount,
            "total_likes":     user.totalLikes,
            "total_points":    user.totalPoints,
            "is_kid_account":  user.isKidAccount,
            "parent_email":    user.parentEmail,
            "join_date":       Timestamp(date: user.joinDate)
        ]
        if let birthday = user.birthday {
            data["birthday"] = Timestamp(date: birthday)
        }
        try await db.collection("users").document(user.id).setData(data, merge: true)
    }

    private func userFromData(_ data: [String: Any], id: String) -> User {
        let joinTimestamp     = data["join_date"] as? Timestamp
        let birthdayTimestamp = data["birthday"] as? Timestamp
        return User(
            id:             id,
            username:       data["username"]        as? String ?? "",
            displayName:    data["display_name"]    as? String ?? "",
            bio:            data["bio"]             as? String ?? "",
            avatarURL:      data["avatar_url"]      as? String ?? "",
            backgroundURL:  data["background_url"]  as? String ?? "",
            followerCount:  data["follower_count"]  as? Int    ?? 0,
            followingCount: data["following_count"] as? Int    ?? 0,
            postCount:      data["post_count"]      as? Int    ?? 0,
            totalLikes:     data["total_likes"]     as? Int    ?? 0,
            totalPoints:    data["total_points"]    as? Int    ?? 0,
            isKidAccount:   data["is_kid_account"]  as? Bool   ?? false,
            parentEmail:    data["parent_email"]    as? String ?? "",
            joinDate:       joinTimestamp?.dateValue() ?? Date(),
            birthday:       birthdayTimestamp?.dateValue()
        )
    }

    // =========================================================================
    // MARK: - User Search
    // =========================================================================

    func searchUsers(query: String, limit: Int = 20) async throws -> [User] {
        let lowered = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !lowered.isEmpty else { return [] }
        let end = lowered + "\u{f8ff}"

        let usernameSnap = try await db.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: lowered)
            .whereField("username", isLessThan: end)
            .limit(to: limit).getDocuments()

        let displaySnap = try await db.collection("users")
            .whereField("display_name", isGreaterThanOrEqualTo: lowered)
            .whereField("display_name", isLessThan: end)
            .limit(to: limit).getDocuments()

        var seen = Set<String>()
        var results: [User] = []
        for doc in usernameSnap.documents + displaySnap.documents {
            let uid = doc.documentID
            guard !seen.contains(uid) else { continue }
            seen.insert(uid)
            results.append(userFromData(doc.data(), id: uid))
        }
        return results
    }

    // =========================================================================
    // MARK: - Following Operations
    // =========================================================================

    func followUser(currentUserId: String, targetUserId: String) async throws {
        let batch = db.batch()
        let followingRef = db.collection("users").document(currentUserId)
            .collection("following").document(targetUserId)
        batch.setData(["followed_at": Timestamp(date: Date())], forDocument: followingRef)

        let followerRef = db.collection("users").document(targetUserId)
            .collection("followers").document(currentUserId)
        batch.setData(["followed_at": Timestamp(date: Date())], forDocument: followerRef)

        batch.updateData(["following_count": FieldValue.increment(Int64(1))],
                         forDocument: db.collection("users").document(currentUserId))
        batch.updateData(["follower_count": FieldValue.increment(Int64(1))],
                         forDocument: db.collection("users").document(targetUserId))
        // Award 1 point to the followed user
        batch.updateData(["total_points": FieldValue.increment(Int64(1))],
                         forDocument: db.collection("users").document(targetUserId))
        try await batch.commit()
    }

    func unfollowUser(currentUserId: String, targetUserId: String) async throws {
        let batch = db.batch()
        batch.deleteDocument(db.collection("users").document(currentUserId)
            .collection("following").document(targetUserId))
        batch.deleteDocument(db.collection("users").document(targetUserId)
            .collection("followers").document(currentUserId))
        batch.updateData(["following_count": FieldValue.increment(Int64(-1))],
                         forDocument: db.collection("users").document(currentUserId))
        batch.updateData(["follower_count": FieldValue.increment(Int64(-1))],
                         forDocument: db.collection("users").document(targetUserId))
        try await batch.commit()
    }

    func isFollowing(currentUserId: String, targetUserId: String) async throws -> Bool {
        let doc = try await db.collection("users").document(currentUserId)
            .collection("following").document(targetUserId).getDocument()
        return doc.exists
    }

    func fetchFollowingIds(userId: String) async throws -> Set<String> {
        let snap = try await db.collection("users").document(userId)
            .collection("following").getDocuments()
        return Set(snap.documents.map { $0.documentID })
    }

    func fetchFollowerCount(userId: String) async throws -> Int {
        let snap = try await db.collection("users").document(userId)
            .collection("followers").getDocuments()
        return snap.documents.count
    }

    func fetchFollowingCount(userId: String) async throws -> Int {
        let snap = try await db.collection("users").document(userId)
            .collection("following").getDocuments()
        return snap.documents.count
    }

    // =========================================================================
    // MARK: - Post Operations
    // =========================================================================

    func publishPost(_ post: LegoPost) async throws {
        var data: [String: Any] = [
            "user_id":          post.userId,
            "username":         post.username,
            "image_url":        post.imageURL,
            "video_url":        post.videoURL,
            "lego_set_number":  post.legoSetNumber,
            "lego_set_name":    post.legoSetName,
            "description":      post.description,
            "like_count":       post.likeCount,
            "comment_count":    post.commentCount,
            "buy_link":         post.buyLink,
            "posted_date":      Timestamp(date: post.postedDate),
            "tags":             post.tags,
            "is_custom_build":  post.isCustomBuild,
            "custom_build_name": post.customBuildName
        ]
        try await db.collection("posts").document(post.id).setData(data)

        // Award 10 points to poster
        try await awardPoints(to: post.userId, points: 10)

        // Increment post_count on user
        try await db.collection("users").document(post.userId)
            .updateData(["post_count": FieldValue.increment(Int64(1))])
    }

    func fetchFeedPosts(limit: Int = 30) async throws -> [LegoPost] {
        let snap = try await db.collection("posts")
            .order(by: "posted_date", descending: true)
            .limit(to: limit)
            .getDocuments()
        return snap.documents.compactMap { postFromDocument($0) }
    }

    func fetchPostsByUser(userId: String) async throws -> [LegoPost] {
        let snap = try await db.collection("posts")
            .whereField("user_id", isEqualTo: userId)
            .order(by: "posted_date", descending: true)
            .getDocuments()
        return snap.documents.compactMap { postFromDocument($0) }
    }

    func deletePost(_ postId: String, userId: String) async throws {
        // Delete comments subcollection
        let commentsSnap = try await db.collection("comments")
            .whereField("post_id", isEqualTo: postId)
            .getDocuments()
        let batch = db.batch()
        for doc in commentsSnap.documents {
            batch.deleteDocument(doc.reference)
        }
        batch.deleteDocument(db.collection("posts").document(postId))
        batch.updateData(["post_count": FieldValue.increment(Int64(-1))],
                         forDocument: db.collection("users").document(userId))
        try await batch.commit()

        // Delete post image from Storage
        let storageRef = Storage.storage().reference()
        try? await storageRef.child("posts/\(postId)/image.jpg").delete()
        try? await storageRef.child("posts/\(postId)/video.mp4").delete()
    }

    private func postFromDocument(_ doc: QueryDocumentSnapshot) -> LegoPost? {
        let data = doc.data()
        let postedDate = (data["posted_date"] as? Timestamp)?.dateValue() ?? Date()
        return LegoPost(
            id:              doc.documentID,
            userId:          data["user_id"]          as? String ?? "",
            username:        data["username"]          as? String ?? "",
            imageURL:        data["image_url"]         as? String ?? "",
            videoURL:        data["video_url"]         as? String ?? "",
            legoSetNumber:   data["lego_set_number"]   as? String ?? "",
            legoSetName:     data["lego_set_name"]     as? String ?? "",
            description:     data["description"]       as? String ?? "",
            likeCount:       data["like_count"]        as? Int    ?? 0,
            commentCount:    data["comment_count"]     as? Int    ?? 0,
            buyLink:         data["buy_link"]          as? String ?? "",
            postedDate:      postedDate,
            tags:            data["tags"]              as? [String] ?? [],
            isCustomBuild:   data["is_custom_build"]   as? Bool   ?? false,
            customBuildName: data["custom_build_name"] as? String ?? ""
        )
    }

    // =========================================================================
    // MARK: - Like Operations
    // =========================================================================

    /// Toggles like for the current user on a post. Returns the new like state.
    func toggleLike(postId: String, postOwnerId: String, currentUserId: String) async throws -> Bool {
        let likeRef = db.collection("posts").document(postId)
            .collection("likes").document(currentUserId)
        let doc = try await likeRef.getDocument()

        let batch = db.batch()
        let postRef = db.collection("posts").document(postId)

        if doc.exists {
            // Unlike
            batch.deleteDocument(likeRef)
            batch.updateData(["like_count": FieldValue.increment(Int64(-1))], forDocument: postRef)
            // Remove 2 points from post owner
            if postOwnerId != currentUserId {
                batch.updateData(["total_points": FieldValue.increment(Int64(-2))],
                                 forDocument: db.collection("users").document(postOwnerId))
                batch.updateData(["total_likes": FieldValue.increment(Int64(-1))],
                                 forDocument: db.collection("users").document(postOwnerId))
            }
            try await batch.commit()
            return false
        } else {
            // Like
            batch.setData(["liked_at": Timestamp(date: Date()), "user_id": currentUserId], forDocument: likeRef)
            batch.updateData(["like_count": FieldValue.increment(Int64(1))], forDocument: postRef)
            // Award 2 points to post owner
            if postOwnerId != currentUserId {
                batch.updateData(["total_points": FieldValue.increment(Int64(2))],
                                 forDocument: db.collection("users").document(postOwnerId))
                batch.updateData(["total_likes": FieldValue.increment(Int64(1))],
                                 forDocument: db.collection("users").document(postOwnerId))
            }
            try await batch.commit()

            // Send notification to post owner
            NotificationManager.shared.sendLikeNotification(postOwnerUsername: postOwnerId)
            return true
        }
    }

    /// Returns the set of post IDs liked by the current user (from a list of post IDs).
    func fetchLikedPostIds(userId: String, postIds: [String]) async throws -> Set<String> {
        var liked = Set<String>()
        // Check likes subcollection for each post in parallel
        await withTaskGroup(of: (String, Bool).self) { group in
            for postId in postIds {
                group.addTask {
                    let doc = try? await self.db.collection("posts").document(postId)
                        .collection("likes").document(userId).getDocument()
                    return (postId, doc?.exists ?? false)
                }
            }
            for await (postId, isLiked) in group {
                if isLiked { liked.insert(postId) }
            }
        }
        return liked
    }

    // =========================================================================
    // MARK: - Comment Operations
    // =========================================================================

    func addComment(to postId: String, postOwnerId: String, text: String, userId: String, username: String) async throws -> Comment {
        let filtered = BadWordFilter.filter(text)
        let commentId = UUID().uuidString
        let commentData: [String: Any] = [
            "post_id":     postId,
            "user_id":     userId,
            "username":    username,
            "text":        filtered,
            "posted_date": Timestamp(date: Date())
        ]
        let batch = db.batch()
        batch.setData(commentData, forDocument: db.collection("comments").document(commentId))
        batch.updateData(["comment_count": FieldValue.increment(Int64(1))],
                         forDocument: db.collection("posts").document(postId))
        // Award 5 points to post owner
        if postOwnerId != userId {
            batch.updateData(["total_points": FieldValue.increment(Int64(5))],
                             forDocument: db.collection("users").document(postOwnerId))
        }
        try await batch.commit()

        NotificationManager.shared.sendCommentNotification(postOwnerUsername: postOwnerId)

        return Comment(
            id: commentId,
            postId: postId,
            userId: userId,
            username: username,
            text: filtered,
            postedDate: Date()
        )
    }

    func fetchComments(for postId: String) async throws -> [Comment] {
        let snap = try await db.collection("comments")
            .whereField("post_id", isEqualTo: postId)
            .order(by: "posted_date")
            .getDocuments()
        return snap.documents.compactMap { doc in
            let data = doc.data()
            let date = (data["posted_date"] as? Timestamp)?.dateValue() ?? Date()
            return Comment(
                id: doc.documentID,
                postId: data["post_id"] as? String ?? postId,
                userId: data["user_id"] as? String ?? "",
                username: data["username"] as? String ?? "",
                text: data["text"] as? String ?? "",
                postedDate: date
            )
        }
    }

    // =========================================================================
    // MARK: - Leaderboard
    // =========================================================================

    /// Fetches users sorted by total_points descending for the global leaderboard.
    func fetchLeaderboard(limit: Int = 50) async throws -> [User] {
        let snap = try await db.collection("users")
            .order(by: "total_points", descending: true)
            .limit(to: limit)
            .getDocuments()
        return snap.documents.map { userFromData($0.data(), id: $0.documentID) }
    }

    // =========================================================================
    // MARK: - Reports
    // =========================================================================

    func reportPost(postId: String, reportedBy: String, reason: String) async throws {
        let data: [String: Any] = [
            "post_id":     postId,
            "reported_by": reportedBy,
            "reason":      reason,
            "reported_at": Timestamp(date: Date())
        ]
        try await db.collection("reports").addDocument(data: data)
    }

    // =========================================================================
    // MARK: - Account Deletion
    // =========================================================================

    /// Completely deletes a user's account: Firestore doc, all posts, comments, Storage files.
    func deleteAccount(userId: String) async throws {
        // 1. Delete all posts by this user
        let postsSnap = try await db.collection("posts")
            .whereField("user_id", isEqualTo: userId)
            .getDocuments()
        for postDoc in postsSnap.documents {
            let postId = postDoc.documentID
            // Delete post comments
            let commentsSnap = try? await db.collection("comments")
                .whereField("post_id", isEqualTo: postId)
                .getDocuments()
            if let comments = commentsSnap {
                for c in comments.documents {
                    try? await c.reference.delete()
                }
            }
            // Delete post Storage files
            try? await Storage.storage().reference().child("posts/\(postId)/image.jpg").delete()
            try? await Storage.storage().reference().child("posts/\(postId)/video.mp4").delete()
            try? await postDoc.reference.delete()
        }

        // 2. Delete profile and background photos from Storage
        try? await Storage.storage().reference().child("users/\(userId)/avatar.jpg").delete()
        try? await Storage.storage().reference().child("users/\(userId)/background.jpg").delete()

        // 3. Delete Firestore user document
        try await db.collection("users").document(userId).delete()

        // 4. Delete Firebase Auth account
        try await Auth.auth().currentUser?.delete()
    }

    // =========================================================================
    // MARK: - Points System
    // =========================================================================

    func awardPoints(to userId: String, points: Int) async throws {
        try await db.collection("users").document(userId)
            .updateData(["total_points": FieldValue.increment(Int64(points))])
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

    func uploadProfilePhoto(imageData: Data, userId: String) async throws -> String {
        return try await uploadImage(imageData: imageData, path: "users/\(userId)/avatar.jpg")
    }

    func uploadBackgroundPhoto(imageData: Data, userId: String) async throws -> String {
        return try await uploadImage(imageData: imageData, path: "users/\(userId)/background.jpg")
    }

    func uploadPostPhoto(imageData: Data, postId: String) async throws -> String {
        return try await uploadImage(imageData: imageData, path: "posts/\(postId)/image.jpg")
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
