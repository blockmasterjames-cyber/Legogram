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
            currentUser = try await FirebaseService.shared.fetchUser(userId: uid)
            // Load photos from Firebase Storage URLs
            await loadPhotosFromFirebase()
        } catch {
            print("[UserSession] Failed to load user profile: \(error.localizedDescription)")
        }
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
    }

    // MARK: - Update Profile

    func updateProfile(displayName: String, bio: String) async throws {
        guard var user = currentUser else { return }
        user.displayName = displayName
        user.bio         = bio
        try await FirebaseService.shared.saveUser(user)
        currentUser = user
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
    }

    // MARK: - Clear

    func clear() {
        currentUser      = nil
        avatarImage      = nil
        backgroundImage  = nil
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
