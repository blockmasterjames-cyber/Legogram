import SwiftUI
import Firebase

// MARK: - App Delegate
// Firebase MUST be configured in the App Delegate's didFinishLaunchingWithOptions,
// which runs BEFORE SwiftUI @StateObject property wrappers are initialized.
// Placing it in the App struct's init() is too late — @StateObject closures
// evaluate before init() body, so any singleton that touches Auth.auth() would crash.

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        configureFirebase()
        return true
    }

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

@main
struct BrickFeedApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var userSession = UserSession.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSession)
        }
    }
}
