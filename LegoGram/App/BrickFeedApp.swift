import SwiftUI

@main
struct BrickFeedApp: App {

    /// Tracks whether the user has already completed onboarding.
    /// Stored in UserDefaults so it persists across launches.
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                // Normal app experience
                ContentView()
            } else {
                // First-launch onboarding (3-slide intro)
                OnboardingView()
            }
        }
    }
}
