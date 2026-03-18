import SwiftUI

/// The root view of the app. Routes to login, onboarding, or main experience
/// based on the user's login and onboarding state.
struct ContentView: View {

    @AppStorage("isLoggedIn")               private var isLoggedIn               = false
    @AppStorage("hasSeenSuggestedBuilders") private var hasSeenSuggestedBuilders = false

    var body: some View {
        if !isLoggedIn {
            // Not logged in — show the onboarding/login flow
            OnboardingView()
        } else if !hasSeenSuggestedBuilders {
            // Logged in but hasn't seen suggested builders yet
            SuggestedBuildersView()
        } else {
            // Fully set up — show the main app
            MainTabView()
        }
    }
}

#Preview {
    ContentView()
}
