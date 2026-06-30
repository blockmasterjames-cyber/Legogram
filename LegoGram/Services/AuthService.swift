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
        let isUnder9: Bool
        if let birthday {
            let age = Calendar.current.dateComponents([.year], from: birthday, to: Date()).year ?? 0
            isUnder13 = age < 13
            isUnder9  = age < 9
        } else {
            isUnder13 = false
            isUnder9  = false
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
            isUnder9:       isUnder9,
            parentEmail:    parentEmail,
            joinDate:       Date(),
            birthday:       birthday
        )

        try await FirebaseService.shared.saveUser(newUser, isNewUser: true)

        // Persist EULA acceptance to the new user's record so we have a
        // per-account record of consent (Apple Guideline 1.2).
        try? await FirebaseService.shared.saveEULAAcceptance(userId: uid)
        UserDefaults.standard.set(true, forKey: "eulaAccepted")

        UserDefaults.standard.set(username, forKey: "profile_username")
        UserDefaults.standard.set(displayName, forKey: "profile_displayName")
        // Safe Mode defaults ON only for under-9 accounts; everyone else starts OFF.
        // Always write an explicit value so no screen relies on the @AppStorage default.
        UserDefaults.standard.set(isUnder9, forKey: "settings_kidSafeMode")

        UserSession.shared.currentUser = newUser
        await followFounderIfNeeded(userId: uid)

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
        await activateDemoModeIfNeeded(email: email)
        isSignedIn = true
    }

    /// Activates demo mode for the Apple reviewer account.
    /// Unlocks all features: kid safe mode off, age verified, all gates removed.
    /// Also seeds sample DM conversations to Firestore so the reviewer can test
    /// the messaging feature on a fresh device.
    func activateDemoModeIfNeeded(email: String) async {
        guard email.lowercased().trimmingCharacters(in: .whitespaces) == "appreview@gmail.com" else { return }
        print("[AuthService] Demo mode activated for appreview@gmail.com — unlocking all features")
        UserDefaults.standard.set(false, forKey: "settings_kidSafeMode")
        UserDefaults.standard.set(true,  forKey: "dm_ageVerified")
        await seedDemoConversationsToFirestore()
    }

    /// Pre-populates the DM inbox with sample conversations in Firestore so
    /// Apple reviewers can immediately see and interact with the messaging
    /// feature on any device, even after the app is reinstalled. Idempotent:
    /// each conversation has a deterministic ID derived from the reviewer's
    /// UID and the other participant — re-running the seed does not duplicate.
    func seedDemoConversationsToFirestore() async {
        guard let reviewerUID = Auth.auth().currentUser?.uid else {
            print("[AuthService] seedDemoConversationsToFirestore aborted — no current Firebase user")
            return
        }
        print("[AuthService] Seeding demo DM conversations to Firestore for reviewer UID=\(reviewerUID)")

        let reviewerUsername = UserSession.shared.username.isEmpty
            ? (UserDefaults.standard.string(forKey: "profile_username") ?? "appreview")
            : UserSession.shared.username
        let now = Date()

        struct SeedSpec {
            let otherId: String
            let otherUsername: String
            let messages: [(senderIsReviewer: Bool, text: String, offset: TimeInterval)]
        }

        let specs: [SeedSpec] = [
            SeedSpec(otherId: "og-brickmaster99", otherUsername: "brickmaster99", messages: [
                (false, "Hey! Love your builds 🧱 Welcome to BrickFeed!", -3600 * 5),
                (true,  "Thanks so much! Huge fan of your Millennium Falcon build!", -3600 * 4),
                (false, "That one took 3 weeks 😅 What sets are you into?", -3600 * 3),
                (true,  "Mostly Star Wars and Icons. The Eiffel Tower is on my wish list!", -3600 * 2),
                (false, "Great taste! 10,001 pieces of pure joy 🗼", -3600),
            ]),
            SeedSpec(otherId: "og-marvelfan-zoe", otherUsername: "marvelfan_zoe", messages: [
                (false, "Just saw your profile — are you a Marvel fan too?? 🦸‍♀️", -7200 * 3),
                (true,  "Absolutely! Black Panther set is incredible.", -7200 * 2),
                (false, "Right?! Wakanda Forever! 🖤💜 I have every Marvel LEGO set lol", -7200),
                (true,  "That's an amazing collection! Do you display them all?", -3600),
                (false, "Whole shelf dedicated to it 😍 I'll post a pic soon!", -1800),
            ]),
            SeedSpec(otherId: "og-citybuilder-max", otherUsername: "citybuilder_max", messages: [
                (false, "Welcome to BrickFeed! Your first post got 50 likes already 🎉", -86400),
                (true,  "Wow really?! This app is so cool, I love the community here", -82800),
                (false, "It's the best LEGO community online! What's your city setup like?", -79200),
            ]),
        ]

        let db = Firestore.firestore()

        for spec in specs {
            // Deterministic conversation ID so re-running the seed is idempotent.
            let convId = "demo-\(reviewerUID)-\(spec.otherId)"
            do {
                let convDoc = try await db.collection("conversations").document(convId).getDocument()
                if convDoc.exists {
                    print("[AuthService] Demo conversation \(convId) already exists in Firestore — skipping.")
                    continue
                }

                let lastMessage = spec.messages.last
                let lastText = lastMessage?.text ?? ""
                let lastDate = now.addingTimeInterval(lastMessage?.offset ?? 0)

                let convData: [String: Any] = [
                    "participant_ids":       [reviewerUID, spec.otherId],
                    "participant_usernames": [reviewerUsername, spec.otherUsername],
                    "created_at":            Timestamp(date: now.addingTimeInterval(-86400 * 2)),
                    "last_message":          lastText,
                    "last_message_date":     Timestamp(date: lastDate)
                ]
                try await db.collection("conversations").document(convId).setData(convData)

                for (idx, m) in spec.messages.enumerated() {
                    let msgId = "demo-msg-\(convId)-\(idx)"
                    let senderId       = m.senderIsReviewer ? reviewerUID       : spec.otherId
                    let senderUsername = m.senderIsReviewer ? reviewerUsername  : spec.otherUsername
                    let msgData: [String: Any] = [
                        "sender_id":       senderId,
                        "sender_username": senderUsername,
                        "text":            m.text,
                        "sent_date":       Timestamp(date: now.addingTimeInterval(m.offset))
                    ]
                    try await db.collection("conversations").document(convId)
                        .collection("messages").document(msgId).setData(msgData)
                }
                print("[AuthService] Seeded conversation \(convId) with \(spec.messages.count) messages to Firestore ✓")
            } catch {
                print("[AuthService] Failed to seed conversation \(convId): \(error.localizedDescription)")
            }
        }

        // Refresh the local DMStore so the Messages tab shows the seeded data
        // immediately, without waiting for the next view appear.
        await DMStore.shared.loadFromFirestore(currentUserId: reviewerUID)
        print("[AuthService] Demo seeding complete. DMStore now has \(DMStore.shared.conversations.count) conversations.")
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
                isUnder9:       false,
                parentEmail:    "",
                joinDate:       Date(),
                birthday:       nil
            )
            do {
                try await FirebaseService.shared.saveUser(placeholderUser, isNewUser: true)
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

        let age = Calendar.current.dateComponents([.year], from: birthday, to: Date()).year ?? 0
        let isUnder13 = age < 13
        let isUnder9  = age < 9

        guard var user = UserSession.shared.currentUser else { return }
        user.username     = username
        user.displayName  = displayName.isEmpty ? user.displayName : displayName
        user.birthday     = birthday
        user.isKidAccount = isUnder13
        user.isUnder9     = isUnder9

        try await FirebaseService.shared.saveUser(user)
        UserSession.shared.currentUser = user

        UserDefaults.standard.set(username, forKey: "profile_username")
        UserDefaults.standard.set(user.displayName, forKey: "profile_displayName")
        // Safe Mode defaults ON only for under-9 accounts; everyone else starts OFF.
        // Always write an explicit value so no screen relies on the @AppStorage default.
        UserDefaults.standard.set(isUnder9, forKey: "settings_kidSafeMode")

        await followFounderIfNeeded(userId: uid)
        needsAppleProfileSetup = false
    }

    // MARK: - Founder Auto-Follow

    /// The founder account every user should follow.
    private static let founderUsername = "blockmasterjames"

    /// Ensures the current user follows the founder. Safe to call on EVERY launch
    /// / sign-in (not just brand-new signups) so EXISTING users also end up
    /// following the founder.
    ///
    /// - Idempotent: it checks the real `following` subcollection and no-ops if
    ///   the follow already exists — no UserDefaults "already ran" flag (which
    ///   could be set before the write actually landed).
    /// - Reliable lookup: resolves the founder via the case-insensitive
    ///   `username_lower` field, so a different stored casing of the username
    ///   doesn't silently miss.
    /// - Persists through the shared `followUser` path, so it benefits from the
    ///   decoupled, merge-based write and works even if the founder doc was
    ///   hand-created/incomplete.
    func followFounderIfNeeded(userId: String) async {
        guard !userId.isEmpty else { return }
        do {
            // Prefer the case-insensitive `username_lower` lookup; fall back to a
            // case-sensitive exact match for a founder doc that predates the
            // username_lower backfill but whose `username` is already lowercase.
            let founderLookup = try await FirebaseService.shared
                .fetchUserByUsernameLower(Self.founderUsername)
                ?? FirebaseService.shared
                .fetchUserByUsername(Self.founderUsername)
            guard let founder = founderLookup else {
                print("[AuthService] \(Self.founderUsername) not found in Firestore — skipping auto-follow")
                return
            }
            // Never auto-follow yourself (the founder's own account).
            guard founder.id != userId else { return }

            // Idempotent guard: skip if already following (real subcollection check).
            if (try? await FirebaseService.shared
                .isFollowing(currentUserId: userId, targetUserId: founder.id)) == true {
                return
            }

            try await FirebaseService.shared.followUser(
                currentUserId: userId,
                targetUserId: founder.id
            )

            // Keep in-memory follow state in sync so the founder shows as followed
            // immediately, using the founder's REAL stored username/uid.
            PostStore.shared.followingUsernames.insert(founder.username)
            FollowingRegistry.shared.follow(uid: founder.id)
            print("[AuthService] Ensured current user follows \(Self.founderUsername) ✓")
        } catch {
            print("[AuthService] Could not auto-follow \(Self.founderUsername): \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private func authError(_ message: String) -> NSError {
        NSError(domain: "AuthService", code: -1,
                userInfo: [NSLocalizedDescriptionKey: message])
    }
}
