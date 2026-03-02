import SwiftUI
import FirebaseCore

@main
struct LegoGramApp: App {

    init() {
        configureFirebase()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    // MARK: - Firebase Configuration

    private func configureFirebase() {
        // Primary path: use GoogleService-Info.plist if it contains real (non-placeholder) values.
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path) as? [String: Any],
           let googleAppID = plist["GOOGLE_APP_ID"] as? String,
           !googleAppID.hasPrefix("REPLACE_WITH"),
           googleAppID != "" {
            // Plist has real Firebase credentials — standard configuration.
            FirebaseApp.configure()
            return
        }

        // Fallback path: configure Firebase programmatically so the app never crashes on
        // launch even when GoogleService-Info.plist contains placeholder values or is absent.
        //
        // ⚠️  To connect to a real Firebase project, replace these values with your actual
        //     credentials from https://console.firebase.google.com → Project Settings → iOS app.
        let options = FirebaseOptions(
            googleAppID: "1:000000000000:ios:0000000000000000000000",
            gcmSenderID: "000000000000"
        )
        options.projectID     = "legogram-app"
        options.storageBucket = "legogram-app.appspot.com"
        options.apiKey        = "REPLACE_WITH_YOUR_API_KEY"
        options.bundleID      = Bundle.main.bundleIdentifier ?? "com.legogram.app"

        guard FirebaseApp.app() == nil else { return }
        FirebaseApp.configure(options: options)
    }
}
