import SwiftUI
import FirebaseAuth
import Firebase

/// The root view of the app.
/// Listens to the Firebase Auth state and routes to:
///   - A loading spinner while auth state is being determined
///   - MainTabView when a user is signed in
///   - LoginView when no user is signed in
struct ContentView: View {

    /// Received from BrickFeedApp via .environmentObject — do NOT redeclare as @StateObject.
    @EnvironmentObject private var userSession: UserSession
    @ObservedObject private var networkMonitor = NetworkMonitor.shared

    private enum AuthState { case loading, loggedIn, loggedOut }
    @State private var authState: AuthState = .loading

    /// Stored so we can remove the listener on disappear and avoid re-adding it on re-appear.
    @State private var authListenerHandle: AuthStateDidChangeListenerHandle?

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                switch authState {
                case .loading:
                    ZStack {
                        Color.darkBackground.ignoresSafeArea()
                        ProgressView()
                            .tint(.legoYellow)
                            .scaleEffect(1.6)
                    }

                case .loggedIn:
                    MainTabView()
                        .environmentObject(userSession)

                case .loggedOut:
                    LoginView()
                }
            }

            // Offline banner — shows when device has no network connection
            if !networkMonitor.isConnected {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 14, weight: .bold))
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
        // Prevent adding a second listener if the view re-appears
        guard authListenerHandle == nil else { return }

        // If Firebase was not configured (placeholder plist), go straight to loggedOut
        // so the app shows LoginView instead of hanging on the loading spinner forever.
        guard FirebaseApp.app() != nil else {
            authState = .loggedOut
            return
        }

        authListenerHandle = Auth.auth().addStateDidChangeListener { _, user in
            Task { @MainActor in
                if user != nil {
                    authState = .loggedIn
                    await userSession.loadCurrentUser()
                } else {
                    authState = .loggedOut
                    userSession.clear()
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UserSession.shared)
}
