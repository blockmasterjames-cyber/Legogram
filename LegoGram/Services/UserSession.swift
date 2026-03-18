import Foundation
import FirebaseAuth
import FirebaseFirestore

/// The single source of truth for the currently signed-in user's profile data.
/// Loaded from Firestore after login and injected as an EnvironmentObject
/// throughout the app so every screen can access the correct username,
/// display name, and bio without hitting UserDefaults or AppStorage.
@MainActor
final class UserSession: ObservableObject {

    // MARK: - Singleton
    static let shared = UserSession()

    // MARK: - Published State

    /// The full Firestore profile for the signed-in user, or nil if not loaded yet.
    @Published var currentUser: User?

    /// True while the profile is being fetched from Firestore.
    @Published var isLoading = false

    private init() {}

    // MARK: - Computed Helpers

    var uid:         String { Auth.auth().currentUser?.uid ?? "" }
    var username:    String { currentUser?.username    ?? "" }
    var displayName: String { currentUser?.displayName ?? "" }
    var bio:         String { currentUser?.bio         ?? "" }

    // MARK: - Load

    /// Fetches the current user's profile from Firestore.
    /// Called automatically by ContentView after Firebase Auth confirms a signed-in user.
    func loadCurrentUser() async {
        guard !uid.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            currentUser = try await FirebaseService.shared.fetchUser(userId: uid)
        } catch {
            print("[UserSession] Failed to load user profile: \(error.localizedDescription)")
        }
    }

    // MARK: - Update Profile

    /// Saves updated display name and bio back to Firestore.
    func updateProfile(displayName: String, bio: String) async throws {
        guard var user = currentUser else { return }
        user.displayName = displayName
        user.bio         = bio
        try await FirebaseService.shared.saveUser(user)
        currentUser = user
    }

    // MARK: - Clear

    /// Called on sign-out to wipe cached user data.
    func clear() {
        currentUser = nil
    }
}
