import SwiftUI
import Firebase

@main
struct BrickFeedApp: App {

    @StateObject private var userSession = UserSession.shared

    /// FirebaseApp.configure() must be called before any Firebase service is used.
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSession)
        }
    }
}
