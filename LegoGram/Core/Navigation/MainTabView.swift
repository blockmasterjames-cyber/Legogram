import SwiftUI

/// The main navigation shell.
/// Sprint 5 upgrade:
/// • iPad landscape: sidebar navigation on left
/// • iPad portrait: bottom tab bar with extra spacing
/// • iPhone: custom bottom tab bar (unchanged)
struct MainTabView: View {

    @ObservedObject private var appState = AppState.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    /// True when we're on an iPad in landscape orientation (wide + short).
    private var isIPadLandscape: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .compact
    }

    /// True when we're on any iPad (portrait or landscape).
    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        if isIPadLandscape {
            iPadSidebarLayout
        } else if isIPad {
            iPadPortraitLayout
        } else {
            iPhoneTabLayout
        }
    }

    // MARK: - iPhone / Compact Layout (existing custom tab bar)

    private var iPhoneTabLayout: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $appState.selectedTab) {
                HomeView()        .tag(AppTab.home)
                SearchView()      .tag(AppTab.search)
                NewPostView()     .tag(AppTab.newPost)
                LeaderboardView() .tag(AppTab.leaderboard)
                ProfileView()     .tag(AppTab.profile)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            customTabBar
        }
        .background(Color.darkBackground)
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - iPad Portrait Layout (tab bar with extra spacing)

    private var iPadPortraitLayout: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $appState.selectedTab) {
                HomeView()        .tag(AppTab.home)
                SearchView()      .tag(AppTab.search)
                NewPostView()     .tag(AppTab.newPost)
                LeaderboardView() .tag(AppTab.leaderboard)
                ProfileView()     .tag(AppTab.profile)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            iPadTabBar
        }
        .background(Color.darkBackground)
        .ignoresSafeArea(edges: .bottom)
    }

    private var iPadTabBar: some View {
        HStack(spacing: 0) {
            tabBarButton(tab: .home,        icon: "house.fill",      label: "Home")
            tabBarButton(tab: .search,      icon: "magnifyingglass", label: "Search")
            iPadPostButton
            tabBarButton(tab: .leaderboard, icon: "trophy.fill",     label: "Leaderboard")
            tabBarButton(tab: .profile,     icon: "person.fill",     label: "Profile")
        }
        .padding(.horizontal, 40)   // more spacing on iPad
        .padding(.top, 14)
        .padding(.bottom, 32)
        .background(Color.cardBackground.shadow(radius: 8, y: -2))
    }

    private var iPadPostButton: some View {
        Button { appState.selectedTab = .newPost } label: {
            ZStack {
                Capsule()
                    .fill(Color.legoRed)
                    .frame(width: 80, height: 52)
                    .shadow(color: .legoRed.opacity(0.5), radius: 8, y: 4)
                HStack(spacing: 6) {
                    Image(systemName: "plus").font(.system(size: 18, weight: .bold))
                    Text("Post").font(.legoCaption.bold())
                }
                .foregroundColor(.white)
            }
            .offset(y: -10)
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
    }

    // MARK: - iPad Landscape / Regular Layout (sidebar on left)

    private var iPadSidebarLayout: some View {
        HStack(spacing: 0) {

            // MARK: Sidebar
            VStack(alignment: .leading, spacing: 0) {

                // Logo at top of sidebar
                LegoGramLogo()
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .padding(.bottom, 20)

                Divider().background(Color.secondaryText.opacity(0.3))
                    .padding(.bottom, 8)

                // Navigation items
                ForEach(sidebarItems, id: \.tab) { item in
                    sidebarButton(item: item)
                }

                Spacer()

                // New Post button at bottom of sidebar
                Button {
                    appState.selectedTab = .newPost
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                        Text("New Post")
                            .font(.legoBody)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color.legoRed)
                    .cornerRadius(14)
                    .padding(.horizontal, 12)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 24)
            }
            .frame(width: 220)
            .background(Color.cardBackground)

            Divider().background(Color.secondaryText.opacity(0.3))

            // MARK: Content Area
            Group {
                switch appState.selectedTab {
                case .home:        HomeView()
                case .search:     SearchView()
                case .newPost:    NewPostView()
                case .leaderboard: LeaderboardView()
                case .profile:    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.darkBackground)
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Sidebar Items

    private struct SidebarItem {
        let tab: AppTab
        let icon: String
        let label: String
    }

    private let sidebarItems: [SidebarItem] = [
        SidebarItem(tab: .home,        icon: "house.fill",      label: "Home"),
        SidebarItem(tab: .search,      icon: "magnifyingglass", label: "Search"),
        SidebarItem(tab: .leaderboard, icon: "trophy.fill",     label: "Leaderboard"),
        SidebarItem(tab: .profile,     icon: "person.fill",     label: "Profile"),
    ]

    private func sidebarButton(item: SidebarItem) -> some View {
        Button {
            appState.selectedTab = item.tab
        } label: {
            HStack(spacing: 14) {
                Image(systemName: item.icon)
                    .font(.system(size: 20))
                    .frame(width: 24)
                Text(item.label)
                    .font(.legoBody)
            }
            .foregroundColor(appState.selectedTab == item.tab ? .legoYellow : .secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                appState.selectedTab == item.tab
                    ? Color.legoYellow.opacity(0.12)
                    : Color.clear
            )
            .cornerRadius(10)
            .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Custom Tab Bar (iPhone)

    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabBarButton(tab: .home,        icon: "house.fill",      label: "Home")
            tabBarButton(tab: .search,      icon: "magnifyingglass", label: "Search")
            postButton
            tabBarButton(tab: .leaderboard, icon: "trophy.fill",     label: "Leaderboard")
            tabBarButton(tab: .profile,     icon: "person.fill",     label: "Profile")
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(Color.cardBackground.shadow(radius: 8, y: -2))
    }

    private func tabBarButton(tab: AppTab, icon: String, label: String) -> some View {
        Button {
            appState.selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 22))
                Text(label).font(.legoCaption)
            }
            .foregroundColor(appState.selectedTab == tab ? .legoYellow : .secondaryText)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var postButton: some View {
        Button {
            appState.selectedTab = .newPost
        } label: {
            ZStack {
                Circle()
                    .fill(Color.legoRed)
                    .frame(width: 60, height: 60)
                    .shadow(color: .legoRed.opacity(0.5), radius: 8, y: 4)
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
            .offset(y: -16)
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
    }
}

#Preview {
    MainTabView()
}
