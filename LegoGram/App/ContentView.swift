import SwiftUI

/// The root view of the app. It hands off control to MainTabView,
/// which holds all five tabs the user can tap on.
struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
}
