import SwiftUI
import Firebase

@main
struct BrickFeedApp: App {

    @StateObject private var userSession = UserSession.shared

    init() {
        configureFirebase()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSession)
        }
    }

    // MARK: - Firebase Setup

    /// Configures Firebase safely:
    /// 1. Guards against double-configure (second call would fatalError).
    /// 2. Guards against placeholder plist values — Firebase Analytics crashes on
    ///    launch if GOOGLE_APP_ID is not a real app identifier.
    private func configureFirebase() {
        // Guard: Firebase is already configured (e.g. during SwiftUI preview refresh)
        guard FirebaseApp.app() == nil else { return }

        // Guard: placeholder plist causes Firebase Analytics to crash on real devices
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let appID = plist["GOOGLE_APP_ID"] as? String,
              !appID.hasPrefix("REPLACE_"),
              let apiKey = plist["API_KEY"] as? String,
              !apiKey.hasPrefix("REPLACE_") else {
            print("""
            ⚠️  [BrickFeedApp] GoogleService-Info.plist contains placeholder values.
                Firebase was NOT configured. Replace the plist with your real Firebase
                credentials from console.firebase.google.com before running on a device.
            """)
            return
        }

        FirebaseApp.configure()
    }
}
