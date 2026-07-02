import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import UIKit

/// The single source of truth for the currently signed-in user's profile data.
@MainActor
final class UserSession: ObservableObject {

    // MARK: - Singleton
    static let shared = UserSession()

    // MARK: - Published State
    @Published var currentUser: User?
    @Published var isLoading = false

    /// Whether the signed-in user is an admin. Derived ONLY from the existence
    /// of `admins/{uid}` (console-only collection) — never from a user-doc
    /// field, so it cannot be self-granted.
    @Published var isAdmin = false

    /// Set true when a banned user is blocked from entering the app. ContentView
    /// observes this to show the suspension screen.
    @Published var isSuspended = false

    /// Cached avatar UIImage loaded from Firebase Storage URL
    @Published var avatarImage: UIImage?
    /// Cached background UIImage loaded from Firebase Storage URL
    @Published var backgroundImage: UIImage?

    private init() {}

    // MARK: - Computed Helpers

    var uid: String {
        guard FirebaseApp.app() != nil else { return "" }
        return Auth.auth().currentUser?.uid ?? ""
    }
    var username:    String { currentUser?.username    ?? "" }
    var displayName: String { currentUser?.displayName ?? "" }
    var bio:         String { currentUser?.bio         ?? "" }
    var avatarURL:   String { currentUser?.avatarURL   ?? "" }

    // MARK: - Load

    func loadCurrentUser() async {
        guard !uid.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let loaded = try await FirebaseService.shared.fetchUser(userId: uid)

            // Ban gate: a banned user is signed out and shown a suspension
            // message instead of entering the app.
            if loaded.isBanned {
                isSuspended = true
                currentUser = nil
                isAdmin = false
                try? Auth.auth().signOut()
                return
            }

            currentUser = loaded
            // Load photos from Firebase Storage URLs
            await loadPhotosFromFirebase()
            // Resolve admin status from the console-only admins collection.
            await refreshAdminStatus()
        } catch {
            print("[UserSession] Failed to load user profile: \(error.localizedDescription)")
        }
    }

    // MARK: - Follow Counts

    /// Adjusts the in-memory `following_count` to match a follow/unfollow the
    /// user just performed, so their own profile updates immediately without a
    /// full re-fetch. The authoritative value still lives in Firestore (written
    /// by `followUser`/`unfollowUser`'s `FieldValue.increment`).
    func adjustFollowingCount(by delta: Int) {
        guard var user = currentUser else { return }
        user.followingCount = max(0, user.followingCount + delta)
        currentUser = user
    }

    /// Re-reads the signed-in user's follower/following counts from Firestore.
    /// Called when the user opens their own profile so the counts reflect
    /// followers gained while the app was open — others following you isn't an
    /// action this device performs, so it can only be picked up by a re-read.
    func refreshFollowCounts() async {
        guard !uid.isEmpty,
              let fresh = try? await FirebaseService.shared.fetchUser(userId: uid),
              var user = currentUser else { return }
        user.followerCount  = fresh.followerCount
        user.followingCount = fresh.followingCount
        currentUser = user
    }

    // MARK: - Points

    /// Bumps the in-memory `total_points` to mirror an award that was just
    /// written to the user's own doc with `FieldValue.increment`, so the
    /// profile/points UI updates immediately without a full re-fetch (same
    /// pattern as `adjustFollowingCount`). Firestore stays authoritative.
    func addPoints(_ delta: Int) {
        guard var user = currentUser else { return }
        user.totalPoints += delta
        currentUser = user
    }

    /// Grants a once-ever +5 profile-completion bonus (avatar / bio / banner)
    /// if the field is actually set and the persistent flag isn't already true.
    /// On success, mirrors the flag + points into `currentUser` via
    /// `markAwarded` so the award can't repeat within this session either.
    /// Failure is logged, not thrown — the profile save itself already
    /// succeeded, and the flag stays unset so the bonus is retried on the next
    /// save of that field.
    private func awardProfileBonusIfNeeded(flagField: String,
                                           alreadyAwarded: Bool,
                                           fieldIsSet: Bool,
                                           markAwarded: (inout User) -> Void) async {
        guard fieldIsSet, !alreadyAwarded, var user = currentUser else { return }
        do {
            try await FirebaseService.shared.grantProfileCompletionBonus(
                userId: user.id, flagField: flagField)
            markAwarded(&user)
            user.totalPoints += 5
            currentUser = user
        } catch {
            print("[UserSession] Profile bonus (\(flagField)) failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Admin Status

    /// Refreshes `isAdmin` by checking whether `admins/{uid}` exists.
    func refreshAdminStatus() async {
        let currentUid = uid
        guard !currentUid.isEmpty else { isAdmin = false; return }
        isAdmin = await FirebaseService.shared.checkIsAdmin(uid: currentUid)
    }

    // MARK: - Load Photos from Firebase Storage URLs

    func loadPhotosFromFirebase() async {
        // Load avatar
        if let avatarURLString = currentUser?.avatarURL,
           !avatarURLString.isEmpty,
           let url = URL(string: avatarURLString) {
            if let (data, _) = try? await URLSession.shared.data(from: url),
               let img = UIImage(data: data) {
                avatarImage = img
            }
        }

        // Load background
        if let bgURLString = currentUser?.backgroundURL,
           !bgURLString.isEmpty,
           let url = URL(string: bgURLString) {
            if let (data, _) = try? await URLSession.shared.data(from: url),
               let img = UIImage(data: data) {
                backgroundImage = img
            }
        }
    }

    // MARK: - Upload and Save Avatar

    func uploadAndSaveAvatar(_ image: UIImage) async throws {
        guard let data = image.jpegData(compressionQuality: 0.80) else { return }
        let url = try await FirebaseService.shared.uploadProfilePhoto(imageData: data, userId: uid)

        // Save URL to Firestore
        guard var user = currentUser else { return }
        user.avatarURL = url
        try await FirebaseService.shared.saveUser(user)
        currentUser = user
        avatarImage = image

        // Once-ever +5 for adding a profile photo. Changing or re-adding the
        // avatar later never re-awards (persistent `awarded_avatar` flag).
        await awardProfileBonusIfNeeded(
            flagField:      "awarded_avatar",
            alreadyAwarded: user.awardedAvatar,
            fieldIsSet:     !url.isEmpty
        ) { $0.awardedAvatar = true }
    }

    // MARK: - Upload and Save Background

    func uploadAndSaveBackground(_ image: UIImage) async throws {
        guard let data = image.jpegData(compressionQuality: 0.80) else { return }
        let url = try await FirebaseService.shared.uploadBackgroundPhoto(imageData: data, userId: uid)

        guard var user = currentUser else { return }
        user.backgroundURL = url
        try await FirebaseService.shared.saveUser(user)
        currentUser = user
        backgroundImage = image

        // Once-ever +5 for adding a banner (persistent `awarded_banner` flag).
        await awardProfileBonusIfNeeded(
            flagField:      "awarded_banner",
            alreadyAwarded: user.awardedBanner,
            fieldIsSet:     !url.isEmpty
        ) { $0.awardedBanner = true }
    }

    // MARK: - Update Profile

    func updateProfile(displayName: String, bio: String) async throws {
        guard var user = currentUser else { return }
        user.displayName = displayName
        user.bio         = bio
        try await FirebaseService.shared.saveUser(user)
        currentUser = user
        await awardBioBonusIfNeeded(bio: bio, alreadyAwarded: user.awardedBio)
    }

    /// Updates display name, username, and bio. Checks username uniqueness before saving.
    func updateProfile(displayName: String, username: String, bio: String) async throws {
        guard var user = currentUser else { return }

        // If username changed, check it's not taken
        let trimmedUsername = username.trimmingCharacters(in: .whitespaces).lowercased()
        if trimmedUsername != user.username.lowercased() {
            if let existing = try? await FirebaseService.shared.fetchUserByUsername(trimmedUsername),
               existing.id != user.id {
                throw ProfileUpdateError.usernameTaken
            }
        }

        user.displayName = displayName
        user.username    = trimmedUsername.isEmpty ? user.username : trimmedUsername
        user.bio         = bio
        try await FirebaseService.shared.saveUser(user)
        currentUser = user

        // Keep UserDefaults in sync
        UserDefaults.standard.set(user.username, forKey: "profile_username")
        UserDefaults.standard.set(user.displayName, forKey: "profile_displayName")

        await awardBioBonusIfNeeded(bio: bio, alreadyAwarded: user.awardedBio)
    }

    /// Once-ever +5 for writing a NON-EMPTY bio, shared by both `updateProfile`
    /// overloads. Clearing and re-writing the bio never re-awards (persistent
    /// `awarded_bio` flag), and clearing never removes the points.
    private func awardBioBonusIfNeeded(bio: String, alreadyAwarded: Bool) async {
        await awardProfileBonusIfNeeded(
            flagField:      "awarded_bio",
            alreadyAwarded: alreadyAwarded,
            fieldIsSet:     !bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        ) { $0.awardedBio = true }
    }

    // MARK: - Privacy

    /// Persists the "Allow Direct Messages" setting to the user's own doc
    /// (`accepts_dms`) and updates the in-memory user so the UI reflects it
    /// immediately. This is an own-doc write, permitted by the Firestore rules.
    func updateAcceptsDMs(_ newValue: Bool) async throws {
        guard var user = currentUser else { return }
        user.acceptsDMs = newValue
        try await FirebaseService.shared.saveUser(user)
        currentUser = user
    }

    // MARK: - Clear

    func clear() {
        currentUser      = nil
        avatarImage      = nil
        backgroundImage  = nil
        isAdmin          = false
        // Note: `isSuspended` is intentionally NOT reset here — it must survive
        // the sign-out that the ban gate triggers so the suspension screen can
        // show. It is cleared when the user dismisses that screen.
    }
}

// MARK: - Profile Update Errors

enum ProfileUpdateError: LocalizedError {
    case usernameTaken
    var errorDescription: String? {
        switch self {
        case .usernameTaken: return "That username is already taken. Please choose a different one."
        }
    }
}
