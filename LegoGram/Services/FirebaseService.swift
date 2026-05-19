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

        // In-app follow notification
        let currentUsername = await UserSession.shared.username
        if !currentUsername.isEmpty {
            Task {
                try? await self.addNotification(
                    toUserId:     targetUserId,
                    type:         .follow,
                    fromUserId:   currentUserId,
                    fromUsername: currentUsername
                )
            }
        }

        // Local push notification
        NotificationManager.shared.sendFollowNotification(from: currentUsername)
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
            "user_id":           post.userId,
            "username":          post.username,
            "image_url":         post.imageURL,
            "video_url":         post.videoURL,
            "image_urls":        post.imageURLs,
            "lego_set_number":   post.legoSetNumber,
            "lego_set_name":     post.legoSetName,
            "description":       post.description,
            "like_count":        post.likeCount,
            "comment_count":     post.commentCount,
            "buy_link":          post.buyLink,
            "posted_date":       Timestamp(date: post.postedDate),
            "tags":              post.tags,
            "is_custom_build":   post.isCustomBuild,
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
            userId:          data["user_id"]           as? String   ?? "",
            username:        data["username"]           as? String   ?? "",
            imageURL:        data["image_url"]          as? String   ?? "",
            videoURL:        data["video_url"]          as? String   ?? "",
            legoSetNumber:   data["lego_set_number"]    as? String   ?? "",
            legoSetName:     data["lego_set_name"]      as? String   ?? "",
            description:     data["description"]        as? String   ?? "",
            likeCount:       data["like_count"]         as? Int      ?? 0,
            commentCount:    data["comment_count"]      as? Int      ?? 0,
            buyLink:         data["buy_link"]           as? String   ?? "",
            postedDate:      postedDate,
            tags:            data["tags"]               as? [String] ?? [],
            isCustomBuild:   data["is_custom_build"]    as? Bool     ?? false,
            customBuildName: data["custom_build_name"]  as? String   ?? "",
            imageURLs:       data["image_urls"]         as? [String] ?? []
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

            // Send local push notification + in-app Firestore notification
            NotificationManager.shared.sendLikeNotification(postOwnerUsername: postOwnerId)
            if postOwnerId != currentUserId {
                let currentUsername = await UserSession.shared.username
                Task {
                    try? await self.addNotification(
                        toUserId:     postOwnerId,
                        type:         .like,
                        fromUserId:   currentUserId,
                        fromUsername: currentUsername,
                        postId:       postId
                    )
                }
            }
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

    func addComment(to postId: String, postOwnerId: String, text: String, userId: String, username: String, avatarURL: String = "") async throws -> Comment {
        let filtered = BadWordFilter.filter(text)
        // Log to moderation if bad words were found
        if filtered != text {
            Task { try? await logModerationEvent(userId: userId, username: username, content: text, filtered: filtered, type: "comment") }
        }
        let commentId = UUID().uuidString
        let commentData: [String: Any] = [
            "post_id":     postId,
            "user_id":     userId,
            "username":    username,
            "text":        filtered,
            "avatar_url":  avatarURL,
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
        if postOwnerId != userId {
            Task {
                try? await self.addNotification(
                    toUserId:     postOwnerId,
                    type:         .comment,
                    fromUserId:   userId,
                    fromUsername: username,
                    postId:       postId
                )
            }
        }

        return Comment(
            id: commentId,
            postId: postId,
            userId: userId,
            username: username,
            text: filtered,
            avatarURL: avatarURL,
            postedDate: Date()
        )
    }

    /// Fetches all comments for a post from the top-level `/comments` collection.
    ///
    /// Build 16 rejection root cause: the previous implementation paired
    /// `.whereField("post_id", isEqualTo: postId)` with `.order(by: "posted_date")`,
    /// which requires a Firestore composite index. On a fresh device that index
    /// did not exist, so the query failed silently and the sheet displayed zero
    /// comments while the denormalized `comment_count` on the post still showed
    /// "5 comments". We now drop the server-side ordering and sort client-side,
    /// removing the composite-index dependency entirely.
    func fetchComments(for postId: String) async throws -> [Comment] {
        print("[FirebaseService] fetchComments — START path=/comments postId=\(postId)")
        do {
            let snap = try await db.collection("comments")
                .whereField("post_id", isEqualTo: postId)
                .getDocuments()
            let comments: [Comment] = snap.documents.compactMap { doc in
                let data = doc.data()
                let date = (data["posted_date"] as? Timestamp)?.dateValue() ?? Date()
                return Comment(
                    id: doc.documentID,
                    postId: data["post_id"] as? String ?? postId,
                    userId: data["user_id"] as? String ?? "",
                    username: data["username"] as? String ?? "",
                    text: data["text"] as? String ?? "",
                    avatarURL: data["avatar_url"] as? String ?? "",
                    postedDate: date
                )
            }
            .sorted { $0.postedDate < $1.postedDate }
            print("[FirebaseService] fetchComments — OK postId=\(postId) returned \(comments.count) comments")
            return comments
        } catch {
            print("[FirebaseService] fetchComments — ERROR postId=\(postId) error=\(error.localizedDescription)")
            print("[FirebaseService] fetchComments — full error: \(error)")
            throw error
        }
    }

    // =========================================================================
    // MARK: - Leaderboard
    // =========================================================================

    /// Fetches users sorted by total_points descending for the global leaderboard.
    /// Falls back to in-memory sort if the ordered Firestore query fails (e.g. missing index).
    func fetchLeaderboard(limit: Int = 50) async throws -> [User] {
        print("[FirebaseService] fetchLeaderboard — requesting top \(limit) users by total_points")
        do {
            let snap = try await db.collection("users")
                .order(by: "total_points", descending: true)
                .limit(to: limit)
                .getDocuments()
            let users = snap.documents.map { userFromData($0.data(), id: $0.documentID) }
            print("[FirebaseService] fetchLeaderboard — ordered query returned \(users.count) users")
            return users
        } catch {
            print("[FirebaseService] fetchLeaderboard — ordered query failed (\(error)), trying fallback")
            // Fallback: fetch without ordering and sort in memory
            let snap = try await db.collection("users")
                .limit(to: 200)
                .getDocuments()
            let users = snap.documents
                .map { userFromData($0.data(), id: $0.documentID) }
                .sorted { $0.totalPoints > $1.totalPoints }
            let result = Array(users.prefix(limit))
            print("[FirebaseService] fetchLeaderboard — fallback returned \(result.count) users")
            return result
        }
    }

    // =========================================================================
    // MARK: - Reports (Apple Guideline 1.2 — UGC safety)
    // =========================================================================

    /// Generic report writer. Used by every "Report" control in the app
    /// (posts, comments, DM messages, DM threads, and the synthetic "block"
    /// report). Writes one document to /reports containing every field Apple
    /// asks moderators to be able to act on.
    func reportContent(
        contentType: String,
        contentId: String,
        reportedUserId: String,
        reportedUsername: String,
        reportedBy: String,
        reportedByUsername: String,
        reason: String,
        contextText: String = ""
    ) async throws {
        let data: [String: Any] = [
            "content_type":         contentType,
            "content_id":           contentId,
            "reported_user_id":     reportedUserId,
            "reported_username":    reportedUsername,
            "reported_by":          reportedBy,
            "reported_by_username": reportedByUsername,
            "reason":               reason,
            "context_text":         contextText,
            "reported_at":          Timestamp(date: Date())
        ]
        try await db.collection("reports").addDocument(data: data)
        print("[FirebaseService] reportContent ✓ type=\(contentType) id=\(contentId) by=\(reportedBy) reason=\(reason)")
    }

    /// Convenience wrapper kept for call sites that already report posts.
    func reportPost(postId: String, postOwnerId: String = "", postOwnerUsername: String = "",
                    reportedBy: String, reportedByUsername: String = "", reason: String) async throws {
        try await reportContent(
            contentType: "post",
            contentId: postId,
            reportedUserId: postOwnerId,
            reportedUsername: postOwnerUsername,
            reportedBy: reportedBy,
            reportedByUsername: reportedByUsername,
            reason: reason
        )
    }

    // =========================================================================
    // MARK: - Blocking (Apple Guideline 1.2 — UGC safety)
    // =========================================================================

    /// Persists a block from `currentUserId` against `targetUserId` and writes
    /// a moderation record to /reports so the developer is notified of the
    /// inappropriate content. The block is stored under
    /// /users/{currentUserId}/blocked_users/{targetUserId} so it is loaded into
    /// the app on every fresh launch — content stays hidden across devices.
    func blockUser(
        currentUserId: String,
        currentUsername: String,
        targetUserId: String,
        targetUsername: String,
        reason: String = "User blocked"
    ) async throws {
        guard !currentUserId.isEmpty, !targetUserId.isEmpty else { return }
        let data: [String: Any] = [
            "blocked_user_id":   targetUserId,
            "blocked_username":  targetUsername,
            "blocked_at":        Timestamp(date: Date())
        ]
        try await db.collection("users").document(currentUserId)
            .collection("blocked_users").document(targetUserId).setData(data)

        // Also create a moderation report so the developer can act on it.
        try? await reportContent(
            contentType: "block",
            contentId: targetUserId,
            reportedUserId: targetUserId,
            reportedUsername: targetUsername,
            reportedBy: currentUserId,
            reportedByUsername: currentUsername,
            reason: reason
        )
        print("[FirebaseService] blockUser ✓ \(currentUserId) blocked \(targetUserId) (@\(targetUsername))")
    }

    func unblockUser(currentUserId: String, targetUserId: String) async throws {
        guard !currentUserId.isEmpty, !targetUserId.isEmpty else { return }
        try await db.collection("users").document(currentUserId)
            .collection("blocked_users").document(targetUserId).delete()
        print("[FirebaseService] unblockUser ✓ \(currentUserId) unblocked \(targetUserId)")
    }

    /// Returns every (userId, username) the current user has blocked. Called on
    /// app start so the in-memory PostStore filter applies before any feed or
    /// DM list query renders content.
    func fetchBlockedUsers(userId: String) async throws -> [(id: String, username: String)] {
        guard !userId.isEmpty else { return [] }
        let snap = try await db.collection("users").document(userId)
            .collection("blocked_users")
            .getDocuments()
        let result: [(id: String, username: String)] = snap.documents.map { doc in
            let data = doc.data()
            return (
                id: data["blocked_user_id"] as? String ?? doc.documentID,
                username: data["blocked_username"] as? String ?? ""
            )
        }
        print("[FirebaseService] fetchBlockedUsers — userId=\(userId) returned \(result.count) blocked users")
        return result
    }

    // =========================================================================
    // MARK: - EULA Acceptance (Apple Guideline 1.2 — UGC safety)
    // =========================================================================

    /// Records that the user has explicitly agreed to the EULA / Terms.
    /// Persisted so the developer can prove acceptance per-user.
    func saveEULAAcceptance(userId: String) async throws {
        guard !userId.isEmpty else { return }
        let data: [String: Any] = [
            "eula_accepted":    true,
            "eula_accepted_at": Timestamp(date: Date())
        ]
        try await db.collection("users").document(userId)
            .setData(data, merge: true)
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
    // MARK: - Fetch User By Username
    // =========================================================================

    /// Looks up a user document by username field. Returns nil if not found.
    func fetchUserByUsername(_ username: String) async throws -> User? {
        let snap = try await db.collection("users")
            .whereField("username", isEqualTo: username)
            .limit(to: 1)
            .getDocuments()
        guard let doc = snap.documents.first else { return nil }
        return userFromData(doc.data(), id: doc.documentID)
    }

    // =========================================================================
    // MARK: - Notifications
    // =========================================================================

    /// Adds a notification document to users/{targetUserId}/notifications.
    func addNotification(
        toUserId: String,
        type: AppNotification.NotificationType,
        fromUserId: String,
        fromUsername: String,
        postId: String = ""
    ) async throws {
        // Don't notify yourself
        guard toUserId != fromUserId else { return }

        let notifId = UUID().uuidString
        let data: [String: Any] = [
            "id":            notifId,
            "type":          type.rawValue,
            "from_user_id":  fromUserId,
            "from_username": fromUsername,
            "post_id":       postId,
            "timestamp":     Timestamp(date: Date()),
            "is_read":       false
        ]
        try await db.collection("users").document(toUserId)
            .collection("notifications").document(notifId).setData(data)
    }

    /// Fetches the most recent 50 notifications for a user, newest first.
    func fetchNotifications(userId: String) async throws -> [AppNotification] {
        let snap = try await db.collection("users").document(userId)
            .collection("notifications")
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .getDocuments()

        return snap.documents.compactMap { doc in
            let data = doc.data()
            guard
                let typeRaw   = data["type"]          as? String,
                let type      = AppNotification.NotificationType(rawValue: typeRaw),
                let fromId    = data["from_user_id"]  as? String,
                let fromUser  = data["from_username"] as? String,
                let ts        = data["timestamp"]     as? Timestamp
            else { return nil }

            return AppNotification(
                id:           doc.documentID,
                type:         type,
                fromUserId:   fromId,
                fromUsername: fromUser,
                postId:       data["post_id"]  as? String ?? "",
                timestamp:    ts.dateValue(),
                isRead:       data["is_read"]  as? Bool   ?? false
            )
        }
    }

    /// Returns the count of unread notifications for a user.
    func fetchUnreadNotificationCount(userId: String) async throws -> Int {
        let snap = try await db.collection("users").document(userId)
            .collection("notifications")
            .whereField("is_read", isEqualTo: false)
            .getDocuments()
        return snap.documents.count
    }

    /// Marks all notifications as read for a user.
    func markAllNotificationsRead(userId: String) async throws {
        let snap = try await db.collection("users").document(userId)
            .collection("notifications")
            .whereField("is_read", isEqualTo: false)
            .getDocuments()

        guard !snap.documents.isEmpty else { return }
        let batch = db.batch()
        for doc in snap.documents {
            batch.updateData(["is_read": true], forDocument: doc.reference)
        }
        try await batch.commit()
    }

    // =========================================================================
    // MARK: - Points System
    // =========================================================================

    // =========================================================================
    // MARK: - Moderation Logging
    // =========================================================================

    func logModerationEvent(userId: String, username: String, content: String, filtered: String, type: String) async throws {
        let data: [String: Any] = [
            "user_id":        userId,
            "username":       username,
            "original":       content,
            "filtered":       filtered,
            "content_type":   type,
            "logged_at":      Timestamp(date: Date())
        ]
        try await db.collection("moderation_logs").addDocument(data: data)
    }

    // =========================================================================
    // MARK: - Direct Message Conversations
    // =========================================================================

    /// Creates or retrieves a conversation between two users.
    /// Returns the conversation document ID.
    func getOrCreateConversation(currentUserId: String, currentUsername: String,
                                  otherUserId: String, otherUsername: String) async throws -> String {
        // Check if conversation already exists (either direction)
        let existingSnap = try await db.collection("conversations")
            .whereField("participant_ids", arrayContains: currentUserId)
            .getDocuments()

        for doc in existingSnap.documents {
            let participantIds = doc.data()["participant_ids"] as? [String] ?? []
            if participantIds.contains(otherUserId) {
                return doc.documentID
            }
        }

        // Create new conversation
        let convId = UUID().uuidString
        let data: [String: Any] = [
            "participant_ids": [currentUserId, otherUserId],
            "participant_usernames": [currentUsername, otherUsername],
            "created_at": Timestamp(date: Date()),
            "last_message": "",
            "last_message_date": Timestamp(date: Date())
        ]
        try await db.collection("conversations").document(convId).setData(data)
        return convId
    }

    /// Sends a message in a conversation and updates the last message preview.
    func sendDMMessage(conversationId: String, senderId: String, senderUsername: String, text: String) async throws {
        let filtered = BadWordFilter.filter(text)
        if filtered != text {
            Task { try? await logModerationEvent(userId: senderId, username: senderUsername, content: text, filtered: filtered, type: "dm") }
        }
        let msgId = UUID().uuidString
        let msgData: [String: Any] = [
            "sender_id":       senderId,
            "sender_username": senderUsername,
            "text":            filtered,
            "sent_date":       Timestamp(date: Date())
        ]
        let batch = db.batch()
        batch.setData(msgData, forDocument: db.collection("conversations")
            .document(conversationId).collection("messages").document(msgId))
        batch.updateData([
            "last_message": filtered,
            "last_message_date": Timestamp(date: Date())
        ], forDocument: db.collection("conversations").document(conversationId))
        try await batch.commit()
    }

    /// Fetches all conversations for the current user, sorted by last message date.
    func fetchConversations(userId: String) async throws -> [DMConversation] {
        let snap = try await db.collection("conversations")
            .whereField("participant_ids", arrayContains: userId)
            .order(by: "last_message_date", descending: true)
            .getDocuments()

        var conversations: [DMConversation] = []
        for doc in snap.documents {
            let data = doc.data()
            let participantIds = data["participant_ids"] as? [String] ?? []
            let participantUsernames = data["participant_usernames"] as? [String] ?? []
            let otherUserId = participantIds.first(where: { $0 != userId }) ?? ""
            let otherUsername = participantUsernames.first(where: { $0 != "" }) ?? ""
            let lastMsg = data["last_message"] as? String ?? ""
            let lastDate = (data["last_message_date"] as? Timestamp)?.dateValue() ?? Date()

            let previewMsg = DMMessage(
                id: "preview",
                senderId: "",
                senderUsername: "",
                text: lastMsg,
                sentDate: lastDate
            )
            let conv = DMConversation(
                id: doc.documentID,
                otherUserId: otherUserId,
                otherUsername: otherUsername,
                messages: [previewMsg]
            )
            conversations.append(conv)
        }
        return conversations
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
