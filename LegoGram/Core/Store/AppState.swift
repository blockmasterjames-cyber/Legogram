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

    /// Bumped to ask HomeView to pop the Home tab back to its feed root and
    /// dismiss any Home-rooted sheets/pushed screens. Every Block confirmation
    /// flows through `returnToHomeFeed()`, which changes this so the user lands
    /// back on the feed after blocking (Issue 1 / Apple Guideline 1.2).
    @Published var homeFeedResetToken = UUID()

    private init() {}

    // MARK: - Block → Return to Home Feed

    /// Returns the user to the root of the Home feed after a successful block.
    /// Switches to the Home tab, signals HomeView to dismiss any presented
    /// sheet/modal/profile-detail and pop any pushed navigation, then refreshes
    /// the feed so the blocked user's content is gone on return.
    func returnToHomeFeed() {
        selectedTab = .home
        homeFeedResetToken = UUID()
        Task { await PostStore.shared.refreshPosts() }
    }
}
