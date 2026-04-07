import SwiftUI

/// The Search screen — find LEGO sets by number/name OR search for users.
/// Sprint 9: Added People search tab that queries Firestore users collection.
struct SearchView: View {

    @State private var searchText    = ""
    @State private var selectedSet: LegoSet?
    @State private var searchTab: SearchTab = .sets
    @State private var userResults: [User] = []
    @State private var isSearchingUsers = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @ObservedObject private var postStore = PostStore.shared

    enum SearchTab: String, CaseIterable {
        case sets   = "Sets"
        case people = "People"
    }

    @State private var apiSearchResults: [LegoSet] = []

    private var searchResults: [LegoSet] {
        let local = LegoSetDatabase.search(searchText)
        // Merge with API results, deduplicating by set number
        let apiOnly = apiSearchResults.filter { api in
            !local.contains { $0.setNumber == api.setNumber }
        }
        return local + apiOnly
    }

    private var popularSets: [LegoSet] {
        ["75192", "71043", "10307", "76210", "21333", "42115", "60380", "76419", "21325", "76916"]
            .compactMap { LegoSetDatabase.set(for: $0) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBackground.ignoresSafeArea()

                if horizontalSizeClass == .regular {
                    iPadLayout
                } else {
                    iPhoneLayout
                }
            }
            .onTapGesture { hideKeyboard() }
            .navigationDestination(item: $selectedSet) { set in
                SetDetailView(set: set)
            }
        }
    }

    // MARK: - iPhone Layout

    private var iPhoneLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerAndSearch
                tabPicker
                if searchTab == .sets {
                    resultsList
                } else {
                    peopleResultsList
                }
                Color.clear.frame(height: 80)
            }
        }
    }

    // MARK: - iPad Layout (side-by-side panels)

    private var iPadLayout: some View {
        HStack(alignment: .top, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerAndSearch
                    tabPicker
                    if !searchText.isEmpty && searchTab == .sets {
                        Text("\(searchResults.count) result\(searchResults.count == 1 ? "" : "s")")
                            .font(.legoCaption)
                            .foregroundColor(.secondaryText)
                            .padding(.horizontal)
                    }
                    Color.clear.frame(height: 80)
                }
            }
            .frame(maxWidth: 360)

            Divider().background(Color.secondaryText.opacity(0.3))

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if searchTab == .sets {
                        resultsList
                    } else {
                        peopleResultsList
                    }
                    Color.clear.frame(height: 80)
                }
                .padding(.horizontal, 8)
            }
        }
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(SearchTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { searchTab = tab }
                } label: {
                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: tab == .sets ? "building.2.crop.circle" : "person.2.fill")
                                .font(.system(size: 14))
                            Text(tab.rawValue)
                                .font(.legoCardTitle)
                        }
                        .foregroundColor(searchTab == tab ? .legoYellow : .secondaryText)

                        Rectangle()
                            .fill(searchTab == tab ? Color.legoYellow : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Shared Components

    @ViewBuilder
    private var headerAndSearch: some View {
        Text("Search")
            .font(.legoScreenTitle)
            .foregroundColor(.lightText)
            .padding(.horizontal)
            .padding(.top, 8)

        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondaryText)

            TextField(searchTab == .sets
                      ? "Set number or name (e.g. 75192 or Falcon)"
                      : "Search by username or display name",
                      text: $searchText)
                .foregroundColor(.lightText)
                .font(.legoBody)
                .autocorrectionDisabled()
                .onSubmit {
                    hideKeyboard()
                    if searchTab == .people { performUserSearch() }
                }
                .onChange(of: searchText) { _, newValue in
                    if searchTab == .people {
                        performUserSearch()
                    } else {
                        // Augment local results with Rebrickable API when sparse
                        let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty && LegoSetDatabase.search(trimmed).count < 3 {
                            Task {
                                let results = (try? await RebrickableService.shared.searchSets(query: trimmed)) ?? []
                                await MainActor.run { apiSearchResults = results }
                            }
                        } else {
                            apiSearchResults = []
                        }
                    }
                }

            if !searchText.isEmpty {
                Button { searchText = ""; userResults = []; apiSearchResults = [] } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondaryText)
                }
            }
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Set Results

    @ViewBuilder
    private var resultsList: some View {
        if searchText.isEmpty {
            popularSetsSection
        } else if searchResults.isEmpty {
            noResultsState
        } else {
            Text("Results for \"\(searchText)\"")
                .font(.legoCardTitle)
                .foregroundColor(.lightText)
                .padding(.horizontal)

            VStack(spacing: 1) {
                ForEach(searchResults) { set in
                    Button { selectedSet = set } label: {
                        SearchSetRow(set: set)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.cardBackground)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    // MARK: - People Results

    @ViewBuilder
    private var peopleResultsList: some View {
        if searchText.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.secondaryText)
                Text("Find People")
                    .font(.legoCardTitle).foregroundColor(.lightText)
                    .multilineTextAlignment(.center)
                Text("Search for BrickFeed users by\nusername or display name")
                    .font(.legoBody).foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 80)
            .padding(.horizontal, 32)
        } else if isSearchingUsers {
            VStack(spacing: 12) {
                ProgressView().tint(.legoYellow)
                Text("Searching users...")
                    .font(.legoCaption).foregroundColor(.secondaryText)
            }
            .padding(.top, 40)
        } else if userResults.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "person.fill.questionmark")
                    .font(.system(size: 48))
                    .foregroundColor(.secondaryText)
                Text("No users found for \"\(searchText)\"")
                    .font(.legoCardTitle).foregroundColor(.lightText)
                Text("Try a different username or name")
                    .font(.legoBody).foregroundColor(.secondaryText)
            }
            .padding(.top, 40).padding(.horizontal)
        } else {
            Text("\(userResults.count) user\(userResults.count == 1 ? "" : "s") found")
                .font(.legoCardTitle)
                .foregroundColor(.lightText)
                .padding(.horizontal)

            VStack(spacing: 1) {
                ForEach(userResults) { user in
                    UserSearchRow(user: user)
                }
            }
            .background(Color.cardBackground)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private var popularSetsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Popular Sets")
                .font(.legoCardTitle)
                .foregroundColor(.lightText)
                .padding(.horizontal)

            VStack(spacing: 1) {
                ForEach(popularSets) { set in
                    Button { selectedSet = set } label: {
                        SearchSetRow(set: set)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.cardBackground)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private var noResultsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondaryText)
            Text("No sets found for \"\(searchText)\"")
                .font(.legoCardTitle)
                .foregroundColor(.lightText)
            Text("Try a set number like 75192\nor a name like Millennium Falcon")
                .font(.legoBody)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
        .padding(.horizontal)
    }

    // MARK: - User Search

    private func performUserSearch() {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else {
            userResults = []
            return
        }
        isSearchingUsers = true
        Task {
            do {
                let results = try await FirebaseService.shared.searchUsers(query: query)
                // Filter out the current user
                let currentUid = UserSession.shared.uid
                userResults = results.filter { $0.id != currentUid }
            } catch {
                print("[SearchView] User search error: \(error.localizedDescription)")
                userResults = []
            }
            isSearchingUsers = false
        }
    }
}

// MARK: - User Search Row

/// A row showing a user result with avatar, username, display name, and follow/unfollow button.
struct UserSearchRow: View {
    let user: User
    @ObservedObject private var postStore = PostStore.shared

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.legoRed)
                .frame(width: 48, height: 48)
                .overlay(
                    Text(String(user.username.prefix(1)).uppercased())
                        .font(.legoCardTitle).foregroundColor(.white)
                )

            // User info
            VStack(alignment: .leading, spacing: 3) {
                Text("@\(user.username)")
                    .font(.legoCardTitle).foregroundColor(.lightText)
                    .lineLimit(1)
                if !user.displayName.isEmpty {
                    Text(user.displayName)
                        .font(.legoCaption).foregroundColor(.secondaryText)
                        .lineLimit(1)
                }
                Text("\(user.postCount) posts")
                    .font(.legoCaption).foregroundColor(.secondaryText)
            }

            Spacer()

            // Follow / Unfollow button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    postStore.toggleFollow(user.username)
                }
                // Also update Firestore
                Task {
                    let currentUid = UserSession.shared.uid
                    guard !currentUid.isEmpty else { return }
                    do {
                        if postStore.isFollowing(user.username) {
                            try await FirebaseService.shared.followUser(currentUserId: currentUid, targetUserId: user.id)
                        } else {
                            try await FirebaseService.shared.unfollowUser(currentUserId: currentUid, targetUserId: user.id)
                        }
                    } catch {
                        print("[UserSearchRow] Follow/unfollow error: \(error)")
                    }
                }
            } label: {
                Text(postStore.isFollowing(user.username) ? "Unfollow" : "Follow")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(postStore.isFollowing(user.username) ? .secondaryText : .white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(postStore.isFollowing(user.username) ? Color.cardBackground : Color.legoRed)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(postStore.isFollowing(user.username) ? Color.secondaryText : Color.clear, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.cardBackground)
    }
}

// MARK: - Search Set Row

/// One result row: real set image (AsyncImage), name, age rating badge, theme, piece count, price.
struct SearchSetRow: View {
    let set: LegoSet

    var body: some View {
        HStack(spacing: 12) {

            // Thumbnail — loads official image from Brickset CDN
            Group {
                if let url = set.setImageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipped()
                        case .failure, .empty:
                            thumbnailPlaceholder
                        @unknown default:
                            thumbnailPlaceholder
                        }
                    }
                } else {
                    thumbnailPlaceholder
                }
            }
            .frame(width: 64, height: 64)
            .cornerRadius(8)
            .clipped()

            // Set details
            VStack(alignment: .leading, spacing: 4) {
                // Name + age badge on same line
                HStack(spacing: 6) {
                    Text(set.name)
                        .font(.legoCardTitle)
                        .foregroundColor(.lightText)
                        .lineLimit(1)
                    AgeRatingBadge(rating: set.ageRating)
                }
                Text("#\(set.setNumber)  ·  \(set.theme)")
                    .font(.legoCaption)
                    .foregroundColor(.secondaryText)
                Label("\(set.pieceCount) pieces", systemImage: "square.grid.3x3.fill")
                    .font(.legoCaption)
                    .foregroundColor(.legoYellow)
            }

            Spacer()

            // Price + Shop link
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(String(format: "%.2f", set.retailPrice))")
                    .font(.legoCardTitle)
                    .foregroundColor(.legoYellow)
                if let url = URL(string: set.legoStoreURL) {
                    Link(destination: url) {
                        Text("Shop")
                            .font(.legoCaption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.legoYellow)
                            .foregroundColor(.darkBackground)
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.cardBackground)
    }

    private var thumbnailPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color.legoRed.opacity(0.3), Color.legoYellow.opacity(0.2)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            VStack(spacing: 2) {
                Image(systemName: "building.2.crop.circle")
                    .font(.system(size: 18))
                    .foregroundColor(.secondaryText)
                Text(set.setNumber)
                    .font(.legoCaption)
                    .foregroundColor(.legoYellow)
                    .minimumScaleFactor(0.7)
            }
        }
    }
}

// Keep old PopularSetPlaceholder so any remaining references compile
struct PopularSetPlaceholder: Identifiable {
    let id = UUID()
    let setNumber: String
    let name: String
    let theme: String
    let posts: Int
}

#Preview {
    SearchView()
}
