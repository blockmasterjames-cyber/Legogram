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
        activateDemoModeIfNeeded(email: email)
        isSignedIn = true
    }

    /// Activates demo mode for the Apple reviewer account.
    /// Unlocks all features: kid safe mode off, age verified, all gates removed.
    /// Also seeds sample DM conversations so the reviewer can test the messaging feature.
    private func activateDemoModeIfNeeded(email: String) {
        guard email.lowercased().trimmingCharacters(in: .whitespaces) == "appreview@gmail.com" else { return }
        print("[AuthService] Demo mode activated for appreview@gmail.com — unlocking all features")
        UserDefaults.standard.set(false, forKey: "settings_kidSafeMode")
        UserDefaults.standard.set(true,  forKey: "dm_ageVerified")
        seedDemoConversations()
    }

    /// Pre-populates the DM inbox with sample conversations so Apple reviewers
    /// can immediately see and interact with the messaging feature.
    private func seedDemoConversations() {
        print("[AuthService] Seeding demo DM conversations for app review account")
        let now = Date()
        // Use the actual Firebase UID so "my" messages render correctly in the thread view.
        let reviewerUID = Auth.auth().currentUser?.uid ?? "demo-reviewer"
        let reviewerUsername = UserDefaults.standard.string(forKey: "profile_username") ?? "appreview"

        let conv1Messages: [DMMessage] = [
            DMMessage(id: "demo-msg-1a", senderId: "og-brickmaster99", senderUsername: "brickmaster99",
                      text: "Hey! Love your builds 🧱 Welcome to BrickFeed!", sentDate: now.addingTimeInterval(-3600 * 5)),
            DMMessage(id: "demo-msg-1b", senderId: reviewerUID, senderUsername: reviewerUsername,
                      text: "Thanks so much! Huge fan of your Millennium Falcon build!", sentDate: now.addingTimeInterval(-3600 * 4)),
            DMMessage(id: "demo-msg-1c", senderId: "og-brickmaster99", senderUsername: "brickmaster99",
                      text: "That one took 3 weeks 😅 What sets are you into?", sentDate: now.addingTimeInterval(-3600 * 3)),
            DMMessage(id: "demo-msg-1d", senderId: reviewerUID, senderUsername: reviewerUsername,
                      text: "Mostly Star Wars and Icons. The Eiffel Tower is on my wish list!", sentDate: now.addingTimeInterval(-3600 * 2)),
            DMMessage(id: "demo-msg-1e", senderId: "og-brickmaster99", senderUsername: "brickmaster99",
                      text: "Great taste! 10,001 pieces of pure joy 🗼", sentDate: now.addingTimeInterval(-3600)),
        ]
        let conv1 = DMConversation(id: "demo-conv-1", otherUserId: "og-brickmaster99",
                                   otherUsername: "brickmaster99", messages: conv1Messages)

        let conv2Messages: [DMMessage] = [
            DMMessage(id: "demo-msg-2a", senderId: "og-marvelfan-zoe", senderUsername: "marvelfan_zoe",
                      text: "Just saw your profile — are you a Marvel fan too?? 🦸‍♀️", sentDate: now.addingTimeInterval(-7200 * 3)),
            DMMessage(id: "demo-msg-2b", senderId: reviewerUID, senderUsername: reviewerUsername,
                      text: "Absolutely! Black Panther set is incredible.", sentDate: now.addingTimeInterval(-7200 * 2)),
            DMMessage(id: "demo-msg-2c", senderId: "og-marvelfan-zoe", senderUsername: "marvelfan_zoe",
                      text: "Right?! Wakanda Forever! 🖤💜 I have every Marvel LEGO set lol", sentDate: now.addingTimeInterval(-7200)),
            DMMessage(id: "demo-msg-2d", senderId: reviewerUID, senderUsername: reviewerUsername,
                      text: "That's an amazing collection! Do you display them all?", sentDate: now.addingTimeInterval(-3600)),
            DMMessage(id: "demo-msg-2e", senderId: "og-marvelfan-zoe", senderUsername: "marvelfan_zoe",
                      text: "Whole shelf dedicated to it 😍 I'll post a pic soon!", sentDate: now.addingTimeInterval(-1800)),
        ]
        let conv2 = DMConversation(id: "demo-conv-2", otherUserId: "og-marvelfan-zoe",
                                   otherUsername: "marvelfan_zoe", messages: conv2Messages)

        let conv3Messages: [DMMessage] = [
            DMMessage(id: "demo-msg-3a", senderId: "og-citybuilder-max", senderUsername: "citybuilder_max",
                      text: "Welcome to BrickFeed! Your first post got 50 likes already 🎉", sentDate: now.addingTimeInterval(-86400)),
            DMMessage(id: "demo-msg-3b", senderId: reviewerUID, senderUsername: reviewerUsername,
                      text: "Wow really?! This app is so cool, I love the community here", sentDate: now.addingTimeInterval(-82800)),
            DMMessage(id: "demo-msg-3c", senderId: "og-citybuilder-max", senderUsername: "citybuilder_max",
                      text: "It's the best LEGO community online! What's your city setup like?", sentDate: now.addingTimeInterval(-79200)),
        ]
        let conv3 = DMConversation(id: "demo-conv-3", otherUserId: "og-citybuilder-max",
                                   otherUsername: "citybuilder_max", messages: conv3Messages)

        DMStore.shared.conversations = [conv1, conv2, conv3]
        print("[AuthService] Demo conversations seeded: \(DMStore.shared.conversations.count) conversations ready")
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
        print("[AuthService] signInWithApple: received ASAuthorization")

        guard FirebaseApp.app() != nil else {
            let msg = "Firebase is not configured. Check GoogleService-Info.plist."
            print("[AuthService] signInWithApple ERROR: \(msg)")
            throw authError(msg)
        }
        print("[AuthService] signInWithApple: Firebase is configured ✓")

        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            let msg = "Invalid Apple credential type — expected ASAuthorizationAppleIDCredential, got \(type(of: authorization.credential))"
            print("[AuthService] signInWithApple ERROR: \(msg)")
            throw authError(msg)
        }
        print("[AuthService] signInWithApple: Apple ID credential cast succeeded ✓")
        print("[AuthService] signInWithApple: userID = \(appleIDCredential.user)")
        print("[AuthService] signInWithApple: email = \(appleIDCredential.email ?? "(nil — normal on repeat sign-ins)")")
        print("[AuthService] signInWithApple: fullName = \(String(describing: appleIDCredential.fullName))")

        guard let appleIDToken = appleIDCredential.identityToken else {
            let msg = "identityToken is nil — Apple did not return a token."
            print("[AuthService] signInWithApple ERROR: \(msg)")
            throw authError(msg)
        }
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            let msg = "Unable to decode Apple identityToken as UTF-8 string."
            print("[AuthService] signInWithApple ERROR: \(msg)")
            throw authError(msg)
        }
        print("[AuthService] signInWithApple: identity token decoded successfully ✓ (length=\(idTokenString.count))")

        guard let nonce = currentNonce else {
            let msg = "currentNonce is nil — prepareAppleSignIn() was not called before this authorization, or the nonce was cleared."
            print("[AuthService] signInWithApple ERROR: \(msg)")
            throw authError(msg)
        }
        print("[AuthService] signInWithApple: nonce present ✓ (length=\(nonce.count))")

        isLoading = true
        errorMessage = nil
        defer {
            isLoading = false
            currentNonce = nil
            print("[AuthService] signInWithApple: defer block — isLoading reset, nonce cleared")
        }

        print("[AuthService] signInWithApple: building OAuthProvider credential…")
        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        print("[AuthService] signInWithApple: calling Auth.auth().signIn(with:)…")
        let result: AuthDataResult
        do {
            result = try await Auth.auth().signIn(with: credential)
        } catch {
            print("[AuthService] signInWithApple ERROR: Firebase signIn(with:) threw — \(error.localizedDescription)")
            print("[AuthService] signInWithApple ERROR detail: \(error)")
            throw error
        }
        let uid = result.user.uid
        print("[AuthService] signInWithApple: Firebase sign-in succeeded ✓ uid=\(uid)")

        let isNewUser = result.additionalUserInfo?.isNewUser ?? false
        print("[AuthService] signInWithApple: isNewUser=\(isNewUser)")

        if isNewUser {
            print("[AuthService] signInWithApple: new user path — creating placeholder profile…")
            let displayName = [
                appleIDCredential.fullName?.givenName,
                appleIDCredential.fullName?.familyName
            ].compactMap { $0 }.joined(separator: " ")

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
            do {
                try await FirebaseService.shared.saveUser(placeholderUser)
                print("[AuthService] signInWithApple: placeholder user saved to Firestore ✓")
            } catch {
                print("[AuthService] signInWithApple ERROR: failed to save placeholder user — \(error.localizedDescription)")
                throw error
            }
            UserSession.shared.currentUser = placeholderUser

            needsAppleProfileSetup = true
            isSignedIn = true
            print("[AuthService] signInWithApple: needsAppleProfileSetup=true, routing to setup screen")
        } else {
            print("[AuthService] signInWithApple: returning user path — loading existing profile…")
            await UserSession.shared.loadCurrentUser()
            needsAppleProfileSetup = false
            isSignedIn = true
            print("[AuthService] signInWithApple: returning user signed in ✓")
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
