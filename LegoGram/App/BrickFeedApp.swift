import SwiftUI

@main
struct BrickFeedApp: App {

    /// Tracks whether the user has already completed onboarding.
    /// Stored in UserDefaults so it persists across launches.
    @AppStorage("hasSeenOnboarding")          private var hasSeenOnboarding        = false

    /// Tracks whether the suggested builders screen has been shown.
    /// Shown once after onboarding, never again.
    @AppStorage("hasSeenSuggestedBuilders")   private var hasSeenSuggestedBuilders = false

    var body: some Scene {
        WindowGroup {
            if !hasSeenOnboarding {
                // First-launch onboarding (3-slide intro)
                OnboardingView()
            } else if !hasSeenSuggestedBuilders {
                // Shown once after onboarding — suggest following blockmasterjames + others
                SuggestedBuildersView()
            } else {
                // Normal app experience
                ContentView()
            }
        }
    }
}
