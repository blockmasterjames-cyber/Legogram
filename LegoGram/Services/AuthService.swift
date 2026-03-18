import Foundation

/// AuthService handles everything to do with signing in, signing out,
/// and creating new BrickFeed accounts.
///
/// NOTE: Firebase has been temporarily removed. These are placeholder
/// implementations that print messages. Real Firebase Auth will be
/// added back in Sprint 3.
@MainActor
final class AuthService: ObservableObject {

    // MARK: - Singleton
    static let shared = AuthService()

    // MARK: - Published State

    /// True when a user is signed in (placeholder: always false until Firebase returns).
    @Published var isSignedIn: Bool = false

    /// True while an auth operation (sign in / sign up) is happening.
    @Published var isLoading: Bool = false

    /// Any error message to show to the user.
    @Published var errorMessage: String?

    private init() {
        print("[AuthService] Initialized (Firebase temporarily removed — Sprint 3 will restore it)")
    }

    // MARK: - Computed Properties

    /// The signed-in user's UID, or nil if no one is signed in.
    var userId: String? { nil }

    // =========================================================================
    // MARK: - Sign Up
    // =========================================================================

    /// Creates a brand new BrickFeed account with email and password.
    func signUp(email: String, password: String, username: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        print("[AuthService] signUp – Firebase temporarily removed. email: \(email), username: \(username)")
    }

    // =========================================================================
    // MARK: - Sign In
    // =========================================================================

    /// Signs in an existing user with their email and password.
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        print("[AuthService] signIn – Firebase temporarily removed. email: \(email)")
    }

    // =========================================================================
    // MARK: - Sign Out
    // =========================================================================

    /// Signs the current user out of the app.
    func signOut() throws {
        isSignedIn = false
        print("[AuthService] signOut – Firebase temporarily removed.")
    }

    // =========================================================================
    // MARK: - Password Reset
    // =========================================================================

    /// Sends a password-reset email to the given address.
    func sendPasswordReset(to email: String) async throws {
        print("[AuthService] sendPasswordReset – Firebase temporarily removed. email: \(email)")
    }
}
