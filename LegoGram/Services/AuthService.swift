import Foundation
import FirebaseAuth

/// AuthService handles everything to do with signing in, signing out,
/// and creating new LegoGram accounts.
///
/// Think of it like the front door lock of the app — it decides
/// who is allowed in and keeps your account safe.
@MainActor
final class AuthService: ObservableObject {

    // MARK: - Singleton
    static let shared = AuthService()

    // MARK: - Published State
    /// The currently signed-in Firebase user. Nil when no one is logged in.
    @Published var currentUser: FirebaseAuth.User?

    /// True while an auth operation (sign in / sign up) is happening.
    @Published var isLoading: Bool = false

    /// Any error message to show to the user.
    @Published var errorMessage: String?

    // MARK: - Private
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    private init() {
        // Listen for Firebase auth state changes so the UI updates automatically
        // when a user signs in or out — even across app restarts.
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Computed Properties

    /// True when a user is signed in.
    var isSignedIn: Bool {
        currentUser != nil
    }

    /// The signed-in user's UID, or nil if no one is signed in.
    var userId: String? {
        currentUser?.uid
    }

    // =========================================================================
    // MARK: - Sign Up
    // =========================================================================

    /// Creates a brand new LegoGram account with email and password.
    /// - Parameters:
    ///   - email: The user's email address.
    ///   - password: The user's chosen password (Firebase requires 6+ characters).
    ///   - username: The @handle the user wants.
    /// - Returns: The newly created Firebase `User`.
    @discardableResult
    func signUp(email: String, password: String, username: String) async throws -> FirebaseAuth.User {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let result = try await Auth.auth().createUser(withEmail: email, password: password)

        // Set the display name to the chosen username
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = username
        try await changeRequest.commitChanges()

        return result.user
    }

    // =========================================================================
    // MARK: - Sign In
    // =========================================================================

    /// Signs in an existing user with their email and password.
    /// - Parameters:
    ///   - email: The user's email address.
    ///   - password: The user's password.
    /// - Returns: The signed-in Firebase `User`.
    @discardableResult
    func signIn(email: String, password: String) async throws -> FirebaseAuth.User {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return result.user
    }

    // =========================================================================
    // MARK: - Sign Out
    // =========================================================================

    /// Signs the current user out of the app.
    func signOut() throws {
        try Auth.auth().signOut()
        currentUser = nil
    }

    // =========================================================================
    // MARK: - Password Reset
    // =========================================================================

    /// Sends a password-reset email to the given address.
    /// - Parameter email: The account's email address.
    func sendPasswordReset(to email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
}
