import Foundation
import FirebaseAuth
import FirebaseFirestore

/// AuthService handles everything to do with signing in, signing out,
/// and creating new BrickFeed accounts using Firebase Authentication.
@MainActor
final class AuthService: ObservableObject {

    // MARK: - Singleton
    static let shared = AuthService()

    // MARK: - Published State

    /// True when a Firebase user is currently signed in.
    @Published var isSignedIn: Bool = false

    /// True while an auth operation is in progress.
    @Published var isLoading: Bool = false

    /// Any error message to surface to the user.
    @Published var errorMessage: String?

    private init() {
        // Reflect the current Firebase auth state on init
        isSignedIn = Auth.auth().currentUser != nil
    }

    // MARK: - Computed Properties

    /// The UID of the currently signed-in user, or nil.
    var userId: String? {
        Auth.auth().currentUser?.uid
    }

    // =========================================================================
    // MARK: - Sign Up
    // =========================================================================

    /// Creates a brand-new BrickFeed account with email and password,
    /// then saves the user's displayName and username to Firestore.
    func signUp(
        email: String,
        password: String,
        username: String,
        displayName: String
    ) async throws {
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        // 1. Create the Firebase Auth account
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let uid    = result.user.uid

        // 2. Build the Firestore user document
        let newUser = User(
            id:             uid,
            username:       username,
            displayName:    displayName,
            bio:            "",
            avatarURL:      "",
            followerCount:  0,
            followingCount: 0,
            postCount:      0,
            totalLikes:     0,
            totalEarnings:  0,
            isKidAccount:   false,
            parentEmail:    "",
            joinDate:       Date()
        )

        // 3. Save to Firestore "users" collection under the Firebase UID
        try await FirebaseService.shared.saveUser(newUser)

        isSignedIn = true
    }

    // =========================================================================
    // MARK: - Sign In
    // =========================================================================

    /// Signs in an existing user with their email and password.
    func signIn(email: String, password: String) async throws {
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        try await Auth.auth().signIn(withEmail: email, password: password)
        isSignedIn = true
    }

    // =========================================================================
    // MARK: - Sign Out
    // =========================================================================

    /// Signs the current user out of Firebase Auth.
    /// ContentView's auth state listener automatically navigates to LoginView.
    func signOut() throws {
        try Auth.auth().signOut()
        isSignedIn = false
    }

    // =========================================================================
    // MARK: - Password Reset
    // =========================================================================

    /// Sends a Firebase password-reset email to the given address.
    func sendPasswordReset(to email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
}
