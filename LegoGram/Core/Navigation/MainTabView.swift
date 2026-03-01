import SwiftUI

/// The main navigation shell of the app.
/// Think of it like a TV remote — tapping a button takes you to a different channel (screen).
/// There are 5 channels: Home, Search, New Post, Leaderboard, and Profile.
///
/// The selected tab is stored in AppState.shared so that any screen in the app
/// can switch tabs programmatically (e.g. NewPostView jumping back to Home after posting).
struct MainTabView: View {

    @ObservedObject private var appState = AppState.shared

    var body: some View {
        ZStack(alignment: .bottom) {

            // MARK: - Page Content
            TabView(selection: $appState.selectedTab) {
                HomeView()
                    .tag(AppTab.home)

                SearchView()
                    .tag(AppTab.search)

                NewPostView()
                    .tag(AppTab.newPost)

                LeaderboardView()
                    .tag(AppTab.leaderboard)

                ProfileView()
                    .tag(AppTab.profile)
            }
            // Hide the system tab bar — we draw our own custom one below.
            .tabViewStyle(.page(indexDisplayMode: .never))

            // MARK: - Custom Tab Bar
            customTabBar
        }
        .background(Color.darkBackground)
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Custom Tab Bar

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
        .padding(.bottom, 28) // Extra bottom padding for the Home Indicator on newer iPhones
        .background(Color.cardBackground.shadow(radius: 8, y: -2))
    }

    // MARK: - Regular Tab Button

    private func tabBarButton(tab: AppTab, icon: String, label: String) -> some View {
        Button {
            appState.selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(label)
                    .font(.legoCaption)
            }
            .foregroundColor(appState.selectedTab == tab ? .legoYellow : .secondaryText)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Centre Post Button (big LEGO-red circle, lifted above the bar)

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
