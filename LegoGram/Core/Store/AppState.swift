import SwiftUI

/// AppTab — the five screens you can tap to in the tab bar.
/// Defined here (not inside MainTabView) so AppState and NewPostView can reference it too.
enum AppTab: Int {
    case home        = 0
    case search      = 1
    case newPost     = 2
    case leaderboard = 3
    case profile     = 4
}

/// AppState is the single source of truth for app-wide UI decisions,
/// like which tab is showing right now.
/// Think of it like a TV remote that every screen can use to change the channel.
@MainActor
final class AppState: ObservableObject {

    // MARK: - Singleton
    static let shared = AppState()

    // MARK: - Published State

    /// Which tab is currently visible. Any screen can change this to navigate.
    @Published var selectedTab: AppTab = .home

    /// Set to true to programmatically open Settings sheet from ProfileView.
    @Published var openSettings: Bool = false

    /// Navigation path for the Home tab's stack. Held here (not as local
    /// HomeView state) so a re-tap of the Home tab bar button can pop the stack
    /// back to the feed by resetting it to empty.
    @Published var homePath = NavigationPath()

    /// Bumped whenever the Home feed should scroll back to the top (e.g. on a
    /// Home-tab re-tap). HomeView observes this token and scrolls to its top
    /// anchor when it changes.
    @Published var scrollHomeToTopToken = UUID()

    private init() {}
}
