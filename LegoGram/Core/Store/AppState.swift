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

    private init() {}
}
