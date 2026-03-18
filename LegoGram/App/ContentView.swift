import SwiftUI
import FirebaseAuth

/// The root view of the app.
/// Listens to the Firebase Auth state and routes to:
///   - A loading spinner while auth state is being determined
///   - MainTabView when a user is signed in
///   - LoginView when no user is signed in
struct ContentView: View {

    @StateObject private var userSession = UserSession.shared

    private enum AuthState { case loading, loggedIn, loggedOut }
    @State private var authState: AuthState = .loading

    var body: some View {
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
        .onAppear(perform: listenToAuthState)
    }

    // MARK: - Firebase Auth State Listener

    private func listenToAuthState() {
        Auth.auth().addStateDidChangeListener { _, user in
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
}
