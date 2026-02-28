import SwiftUI

/// The main navigation of the app.
/// Think of this like a TV remote — tapping a button takes you to a different channel (screen).
/// There are 5 channels: Home, Search, New Post, Leaderboard, and Profile.
struct MainTabView: View {

    @State private var selectedTab: Tab = .home

    enum Tab: Int {
        case home        = 0
        case search      = 1
        case newPost     = 2
        case leaderboard = 3
        case profile     = 4
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: - Page Content
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(Tab.home)

                SearchView()
                    .tag(Tab.search)

                NewPostView()
                    .tag(Tab.newPost)

                LeaderboardView()
                    .tag(Tab.leaderboard)

                ProfileView()
                    .tag(Tab.profile)
            }
            // Hide the default system tab bar so we can draw our custom one.
            .tabViewStyle(.page(indexDisplayMode: .never))

            // MARK: - Custom Tab Bar
            customTabBar
        }
        .background(Color.darkBackground)
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Custom Tab Bar View
    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabBarButton(tab: .home,        icon: "house.fill",          label: "Home")
            tabBarButton(tab: .search,      icon: "magnifyingglass",     label: "Search")
            postButton
            tabBarButton(tab: .leaderboard, icon: "trophy.fill",         label: "Leaderboard")
            tabBarButton(tab: .profile,     icon: "person.fill",         label: "Profile")
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 28) // Extra bottom padding for home indicator bar on newer iPhones
        .background(Color.cardBackground.shadow(radius: 8, y: -2))
    }

    // MARK: - Regular Tab Bar Button
    private func tabBarButton(tab: Tab, icon: String, label: String) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(label)
                    .font(.legoCaption)
            }
            .foregroundColor(selectedTab == tab ? .legoYellow : .secondaryText)
            .frame(maxWidth: .infinity)
        }
        // Badge support: overlay an empty badge view here in a future sprint
        // .overlay(alignment: .topTrailing) { BadgeView(count: notificationCount) }
    }

    // MARK: - Center Post Button (bigger + LEGO red)
    private var postButton: some View {
        Button {
            selectedTab = .newPost
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
            .offset(y: -16) // Lift the circle above the tab bar
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    MainTabView()
}
