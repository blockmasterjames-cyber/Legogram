import SwiftUI
import FirebaseAuth
import Firebase

/// The root view of the app.
/// Routes to: loading spinner → Apple setup screen → onboarding → feed OR login.
struct ContentView: View {

    @EnvironmentObject private var userSession: UserSession
    @ObservedObject private var authService    = AuthService.shared
    @ObservedObject private var networkMonitor = NetworkMonitor.shared

    private enum AuthState { case loading, loggedIn, loggedOut }
    @State private var authState: AuthState = .loading
    @State private var authListenerHandle: AuthStateDidChangeListenerHandle?

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    /// Set to true ONLY after the user explicitly taps "I Agree" on the
    /// EULAAgreementView. Apple Guideline 1.2 requires an explicit agreement
    /// gate before a user can sign up OR sign in — passive Terms text is not
    /// sufficient. This flag persists in UserDefaults so the gate is shown
    /// once per device and enforced on every fresh install.
    @AppStorage("eulaAccepted") private var eulaAccepted = false

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                switch authState {
                case .loading:
                    ZStack {
                        Color.darkBackground.ignoresSafeArea()
                        VStack(spacing: 20) {
                            BrickFeedLogo()
                            ProgressView().tint(.legoYellow).scaleEffect(1.6)
                        }
                    }

                case .loggedIn:
                    if !eulaAccepted {
                        // Existing signed-in user who hasn't yet accepted the
                        // EULA gate (e.g. they updated the app). Apple Guideline
                        // 1.2 requires explicit agreement before account use, so
                        // we enforce it before MainTabView renders.
                        EULAAgreementView()
                    } else if authService.needsAppleProfileSetup {
                        // New Apple Sign In user — must complete username + birthday setup
                        AppleSignInSetupView()
                    } else if !hasSeenOnboarding {
                        // First-time login — show onboarding carousel
                        OnboardingView()
                    } else {
                        MainTabView()
                            .environmentObject(userSession)
                    }

                case .loggedOut:
                    if eulaAccepted {
                        LoginView()
                    } else {
                        EULAAgreementView()
                    }
                }
            }

            // Offline banner
            if !networkMonitor.isConnected {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash").font(.system(size: 14, weight: .bold))
                    Text("No Internet Connection")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.legoRed)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut, value: networkMonitor.isConnected)
            }
        }
        .onAppear(perform: listenToAuthState)
        .onDisappear {
            if let handle = authListenerHandle {
                Auth.auth().removeStateDidChangeListener(handle)
                authListenerHandle = nil
            }
        }
    }

    // MARK: - Firebase Auth State Listener

    private func listenToAuthState() {
        guard authListenerHandle == nil else { return }
        guard FirebaseApp.app() != nil else {
            authState = .loggedOut
            return
        }

        authListenerHandle = Auth.auth().addStateDidChangeListener { _, user in
            Task { @MainActor in
                if let user {
                    authState = .loggedIn
                    await userSession.loadCurrentUser()

                    // Demo seeding for the Apple reviewer account. Idempotent —
                    // skips if the seed conversations already exist in Firestore.
                    // Needed here because Firebase auto-restores the session on
                    // relaunch, bypassing the signIn() path.
                    if let email = user.email {
                        await AuthService.shared.activateDemoModeIfNeeded(email: email)
                    }

                    // Load following list from Firestore into PostStore
                    if let followingIds = try? await FirebaseService.shared.fetchFollowingIds(userId: user.uid) {
                        for id in followingIds {
                            if let ogAccount = OGAccountsService.ogAccounts.first(where: { $0.id == id }) {
                                PostStore.shared.followingUsernames.insert(ogAccount.username)
                            }
                        }
                    }

                    // Load blocked users from Firestore so the content filter
                    // applies before any feed / DM / comment query renders.
                    // Apple Guideline 1.2 requires blocks to persist across
                    // launches and apply on a fresh device — this is the load
                    // path that makes that work.
                    await PostStore.shared.loadBlockedUsers(currentUserId: user.uid)

                    // Persist EULA acceptance to the user's Firestore doc so
                    // the developer has a record of the explicit agreement.
                    if UserDefaults.standard.bool(forKey: "eulaAccepted") {
                        try? await FirebaseService.shared.saveEULAAcceptance(userId: user.uid)
                    }

                    // Load Firestore posts into feed
                    do {
                        let posts = try await FirebaseService.shared.fetchFeedPosts()
                        if !posts.isEmpty {
                            PostStore.shared.posts = posts
                        } else {
                            // Fall back to OG posts if no Firestore posts yet
                            OGAccountsService.shared.loadOGPostsIfNeeded()
                        }
                    } catch {
                        OGAccountsService.shared.loadOGPostsIfNeeded()
                    }

                    // Load liked post IDs from Firestore
                    let postIds = PostStore.shared.posts.map { $0.id }
                    if let liked = try? await FirebaseService.shared.fetchLikedPostIds(userId: user.uid, postIds: postIds) {
                        PostStore.shared.likedPostIDs = liked
                    }

                } else {
                    authState = .loggedOut
                    userSession.clear()
                    PostStore.shared.followingUsernames.removeAll()
                    PostStore.shared.posts.removeAll()
                    PostStore.shared.likedPostIDs.removeAll()
                    PostStore.shared.blockedUserIDs.removeAll()
                    PostStore.shared.blockedUsers.removeAll()
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UserSession.shared)
}
