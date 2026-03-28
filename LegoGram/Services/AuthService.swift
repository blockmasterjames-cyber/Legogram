import Foundation
import FirebaseAuth
import Firebase
import FirebaseFirestore
import AuthenticationServices
import CryptoKit

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
        // Only check auth state if Firebase has been configured;
        // otherwise Auth.auth() will crash with "no default FirebaseApp".
        if FirebaseApp.app() != nil {
            isSignedIn = Auth.auth().currentUser != nil
        }
    }

    // MARK: - Computed Properties

    /// The UID of the currently signed-in user, or nil.
    var userId: String? {
        guard FirebaseApp.app() != nil else { return nil }
        return Auth.auth().currentUser?.uid
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
        guard FirebaseApp.app() != nil else {
            throw authError("Firebase is not configured. Check GoogleService-Info.plist.")
        }

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
        guard FirebaseApp.app() != nil else {
            throw authError("Firebase is not configured. Check GoogleService-Info.plist.")
        }

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
        guard FirebaseApp.app() != nil else { return }
        try Auth.auth().signOut()
        isSignedIn = false
    }

    // =========================================================================
    // MARK: - Password Reset
    // =========================================================================

    /// Sends a Firebase password-reset email to the given address.
    func sendPasswordReset(to email: String) async throws {
        guard FirebaseApp.app() != nil else {
            throw authError("Firebase is not configured. Check GoogleService-Info.plist.")
        }
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    // =========================================================================
    // MARK: - Sign in with Apple
    // =========================================================================

    /// A random nonce used for the current Sign in with Apple request.
    /// Must be set before starting the Apple auth flow and read in the delegate callback.
    private(set) var currentNonce: String?

    /// Generates a cryptographically secure random nonce string.
    /// Returns nil if the system random number generator fails.
    func randomNonceString(length: Int = 32) -> String? {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        guard errorCode == errSecSuccess else {
            print("[AuthService] SecRandomCopyBytes failed with code \(errorCode)")
            return nil
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    /// Returns the SHA256 hash of the input string, hex-encoded.
    func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Prepares the Apple sign-in request by generating a fresh nonce.
    /// Returns the SHA256-hashed nonce to embed in the ASAuthorizationAppleIDRequest,
    /// or nil if nonce generation fails.
    func prepareAppleSignIn() -> String? {
        guard let nonce = randomNonceString() else { return nil }
        currentNonce = nonce
        return sha256(nonce)
    }

    /// Signs in (or creates an account) using Apple credential from ASAuthorization.
    func signInWithApple(authorization: ASAuthorization) async throws {
        guard FirebaseApp.app() != nil else {
            throw authError("Firebase is not configured. Check GoogleService-Info.plist.")
        }

        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw authError("Invalid Apple credential type.")
        }

        guard let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw authError("Unable to retrieve Apple ID token.")
        }

        guard let nonce = currentNonce else {
            throw authError("Missing nonce. The Sign in with Apple request was not prepared correctly.")
        }

        isLoading = true
        errorMessage = nil
        defer {
            isLoading = false
            currentNonce = nil   // consumed — prevent replay
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        let result = try await Auth.auth().signIn(with: credential)
        let uid = result.user.uid

        // If this is a new user, save a Firestore profile
        let isNewUser = result.additionalUserInfo?.isNewUser ?? false
        if isNewUser {
            let displayName = [
                appleIDCredential.fullName?.givenName,
                appleIDCredential.fullName?.familyName
            ].compactMap { $0 }.joined(separator: " ")

            let username = "builder_\(uid.prefix(8))"

            let newUser = User(
                id:             uid,
                username:       username,
                displayName:    displayName.isEmpty ? "BrickFeed Builder" : displayName,
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
            try await FirebaseService.shared.saveUser(newUser)
        }

        isSignedIn = true
    }

    // MARK: - Helpers

    private func authError(_ message: String) -> NSError {
        NSError(domain: "AuthService", code: -1,
                userInfo: [NSLocalizedDescriptionKey: message])
    }
}
