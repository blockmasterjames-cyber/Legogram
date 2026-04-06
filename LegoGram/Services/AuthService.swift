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
    @Published var isSignedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    /// Set to true when a new Apple Sign In user still needs to complete profile setup
    /// (choose username and enter birthday). ContentView checks this to route to setup screen.
    @Published var needsAppleProfileSetup: Bool = false

    private init() {
        if FirebaseApp.app() != nil {
            isSignedIn = Auth.auth().currentUser != nil
        }
    }

    // MARK: - Computed Properties

    var userId: String? {
        guard FirebaseApp.app() != nil else { return nil }
        return Auth.auth().currentUser?.uid
    }

    // =========================================================================
    // MARK: - Sign Up
    // =========================================================================

    func signUp(
        email: String,
        password: String,
        username: String,
        displayName: String,
        birthday: Date? = nil,
        parentEmail: String = ""
    ) async throws {
        guard FirebaseApp.app() != nil else {
            throw authError("Firebase is not configured. Check GoogleService-Info.plist.")
        }

        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let uid    = result.user.uid

        let isUnder13: Bool
        if let birthday {
            let age = Calendar.current.dateComponents([.year], from: birthday, to: Date()).year ?? 0
            isUnder13 = age < 13
        } else {
            isUnder13 = false
        }

        let newUser = User(
            id:             uid,
            username:       username,
            displayName:    displayName,
            bio:            "",
            avatarURL:      "",
            backgroundURL:  "",
            followerCount:  0,
            followingCount: 0,
            postCount:      0,
            totalLikes:     0,
            totalPoints:    0,
            isKidAccount:   isUnder13,
            parentEmail:    parentEmail,
            joinDate:       Date(),
            birthday:       birthday
        )

        try await FirebaseService.shared.saveUser(newUser)

        UserDefaults.standard.set(username, forKey: "profile_username")
        UserDefaults.standard.set(displayName, forKey: "profile_displayName")
        if isUnder13 {
            UserDefaults.standard.set(true, forKey: "settings_kidSafeMode")
        }

        UserSession.shared.currentUser = newUser
        await OGAccountsService.shared.setupNewUser(userId: uid)

        isSignedIn = true
    }

    // =========================================================================
    // MARK: - Sign In
    // =========================================================================

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

    func signOut() throws {
        guard FirebaseApp.app() != nil else { return }
        try Auth.auth().signOut()
        isSignedIn = false
        needsAppleProfileSetup = false
    }

    // =========================================================================
    // MARK: - Password Reset
    // =========================================================================

    func sendPasswordReset(to email: String) async throws {
        guard FirebaseApp.app() != nil else {
            throw authError("Firebase is not configured. Check GoogleService-Info.plist.")
        }
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    // =========================================================================
    // MARK: - Sign in with Apple
    // =========================================================================

    private(set) var currentNonce: String?

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

    func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    func prepareAppleSignIn() -> String? {
        guard let nonce = randomNonceString() else { return nil }
        currentNonce = nonce
        return sha256(nonce)
    }

    /// Signs in (or creates) with Apple credential.
    /// For NEW users: sets needsAppleProfileSetup = true so ContentView shows the setup screen.
    /// For RETURNING users: goes straight to the feed.
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
            currentNonce = nil
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        let result = try await Auth.auth().signIn(with: credential)
        let uid = result.user.uid

        let isNewUser = result.additionalUserInfo?.isNewUser ?? false
        if isNewUser {
            // New Apple user — needs to set up username and birthday
            // Store the Apple user ID and provisional display name so the setup screen can use them
            let displayName = [
                appleIDCredential.fullName?.givenName,
                appleIDCredential.fullName?.familyName
            ].compactMap { $0 }.joined(separator: " ")

            // Create a minimal placeholder user doc so Firestore rules don't block
            let placeholderUser = User(
                id:             uid,
                username:       "builder_\(uid.prefix(8))",
                displayName:    displayName.isEmpty ? "BrickFeed Builder" : displayName,
                bio:            "",
                avatarURL:      "",
                backgroundURL:  "",
                followerCount:  0,
                followingCount: 0,
                postCount:      0,
                totalLikes:     0,
                totalPoints:    0,
                isKidAccount:   false,
                parentEmail:    "",
                joinDate:       Date(),
                birthday:       nil
            )
            try await FirebaseService.shared.saveUser(placeholderUser)
            UserSession.shared.currentUser = placeholderUser

            // Signal ContentView to show setup screen
            needsAppleProfileSetup = true
            isSignedIn = true
        } else {
            // Returning Apple user — load their profile and go to feed
            await UserSession.shared.loadCurrentUser()
            needsAppleProfileSetup = false
            isSignedIn = true
        }
    }

    /// Called after the Apple Sign In setup screen to finalize the user's profile.
    func completeAppleSetup(username: String, displayName: String, birthday: Date) async throws {
        guard let uid = userId else { return }

        let isUnder13: Bool = {
            let age = Calendar.current.dateComponents([.year], from: birthday, to: Date()).year ?? 0
            return age < 13
        }()

        guard var user = UserSession.shared.currentUser else { return }
        user.username     = username
        user.displayName  = displayName.isEmpty ? user.displayName : displayName
        user.birthday     = birthday
        user.isKidAccount = isUnder13

        try await FirebaseService.shared.saveUser(user)
        UserSession.shared.currentUser = user

        UserDefaults.standard.set(username, forKey: "profile_username")
        UserDefaults.standard.set(user.displayName, forKey: "profile_displayName")
        if isUnder13 {
            UserDefaults.standard.set(true, forKey: "settings_kidSafeMode")
        }

        await OGAccountsService.shared.setupNewUser(userId: uid)
        needsAppleProfileSetup = false
    }

    // MARK: - Helpers

    private func authError(_ message: String) -> NSError {
        NSError(domain: "AuthService", code: -1,
                userInfo: [NSLocalizedDescriptionKey: message])
    }
}
