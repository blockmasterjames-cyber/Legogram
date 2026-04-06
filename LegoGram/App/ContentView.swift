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
                    if authService.needsAppleProfileSetup {
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
                    LoginView()
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

                    // Load following list from Firestore into PostStore
                    if let followingIds = try? await FirebaseService.shared.fetchFollowingIds(userId: user.uid) {
                        for id in followingIds {
                            if let ogAccount = OGAccountsService.ogAccounts.first(where: { $0.id == id }) {
                                PostStore.shared.followingUsernames.insert(ogAccount.username)
                            }
                        }
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

                    // Request notification permission after first login (post-onboarding)
                    if hasSeenOnboarding {
                        await NotificationManager.shared.requestPermission()
                    }

                } else {
                    authState = .loggedOut
                    userSession.clear()
                    PostStore.shared.followingUsernames.removeAll()
                    PostStore.shared.posts.removeAll()
                    PostStore.shared.likedPostIDs.removeAll()
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UserSession.shared)
}
