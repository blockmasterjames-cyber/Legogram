import SwiftUI
import FirebaseCore

@main
struct LegoGramApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
